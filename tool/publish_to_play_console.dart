import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

const String defaultPackageName = 'neriquest.calculator';
const String defaultBundlePath = 'build/app/outputs/bundle/release/app-release.aab';
const String defaultKeyPath = 'android/play-service-account.json';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'key-file',
      abbr: 'k',
      defaultsTo: defaultKeyPath,
      help: 'Path to the Google Play Service Account JSON key file',
    )
    ..addOption(
      'package-name',
      abbr: 'p',
      defaultsTo: defaultPackageName,
      help: 'Android Application ID / Package Name',
    )
    ..addOption(
      'bundle-path',
      abbr: 'b',
      defaultsTo: defaultBundlePath,
      help: 'Path to the .aab Android App Bundle file',
    )
    ..addOption(
      'track',
      abbr: 't',
      defaultsTo: 'internal',
      allowed: ['internal', 'alpha', 'beta', 'production'],
      help: 'Release track on Google Play Console',
    )
    ..addOption(
      'status',
      abbr: 's',
      defaultsTo: 'completed',
      allowed: ['completed', 'draft', 'inProgress', 'halted'],
      help: 'Release status',
    )
    ..addOption(
      'user-fraction',
      defaultsTo: null,
      help: 'Fraction of users for staged rollout (e.g. 0.1 for 10%) when status is inProgress',
    )
    ..addOption(
      'release-notes',
      defaultsTo: null,
      help: 'Optional release notes text (default language: en-US)',
    )
    ..addFlag(
      'build',
      defaultsTo: false,
      help: 'Automatically run "flutter build appbundle --release" before publishing',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    );

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    stdout.writeln('Error parsing arguments: $e');
    stdout.writeln(parser.usage);
    exit(1);
  }

  if (args['help'] as bool) {
    stdout.writeln('Google Play Console App Bundle Publisher');
    stdout.writeln('========================================');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final keyFilePath = args['key-file'] as String;
  final packageName = args['package-name'] as String;
  final bundlePath = args['bundle-path'] as String;
  final track = args['track'] as String;
  final status = args['status'] as String;
  final userFractionStr = args['user-fraction'] as String?;
  final releaseNotes = args['release-notes'] as String?;
  final shouldBuild = args['build'] as bool;

  // 1. Build appbundle if requested
  if (shouldBuild) {
    stdout.writeln('==> Building release Android App Bundle (flutter build appbundle --release)...');
    final buildProcess = await Process.start(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['build', 'appbundle', '--release'],
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await buildProcess.exitCode;
    if (exitCode != 0) {
      stderr.writeln('Error: flutter build appbundle failed with exit code $exitCode');
      exit(exitCode);
    }
    stdout.writeln('==> App Bundle built successfully.');
  }

  // 2. Validate bundle file exists
  final bundleFile = File(bundlePath);
  if (!bundleFile.existsSync()) {
    stderr.writeln('Error: App Bundle not found at "$bundlePath".');
    stderr.writeln('Run "flutter build appbundle --release" first, or pass --build.');
    exit(1);
  }

  // 3. Resolve and validate service account key
  String? rawKeyJson;
  final envKeyJson = Platform.environment['PLAY_SERVICE_ACCOUNT_JSON'];
  final envGoogleAppCreds = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];

  if (envKeyJson != null && envKeyJson.trim().startsWith('{')) {
    rawKeyJson = envKeyJson;
    stdout.writeln('==> Using credentials from PLAY_SERVICE_ACCOUNT_JSON environment variable.');
  } else {
    String resolvedPath = keyFilePath;
    if (!File(resolvedPath).existsSync() && envGoogleAppCreds != null && File(envGoogleAppCreds).existsSync()) {
      resolvedPath = envGoogleAppCreds;
    }

    final keyFile = File(resolvedPath);
    if (!keyFile.existsSync()) {
      stderr.writeln('Error: Google Play Service Account JSON key not found at "$resolvedPath".');
      stderr.writeln('');
      stderr.writeln('To set up command-line publishing for neriquest@gmail.com:');
      stderr.writeln('1. Open Google Play Console (logged in as neriquest@gmail.com) -> Setup -> API access.');
      stderr.writeln('2. Link your Google Cloud project and create a Service Account.');
      stderr.writeln('3. Grant "Release Manager" permissions for neriquest.calculator.');
      stderr.writeln('4. Download the JSON key file and save it as: android/play-service-account.json');
      stderr.writeln('   (or set the GOOGLE_APPLICATION_CREDENTIALS environment variable).');
      exit(1);
    }
    rawKeyJson = await keyFile.readAsString();
    stdout.writeln('==> Authenticating using Service Account key: $resolvedPath');
  }

  // 4. Authenticate with Google Play API
  final Map<String, dynamic> keyJson;
  try {
    keyJson = jsonDecode(rawKeyJson) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Error reading key file JSON: $e');
    exit(1);
  }

  final credentials = ServiceAccountCredentials.fromJson(keyJson);
  final client = await clientViaServiceAccount(
    credentials,
    [AndroidPublisherApi.androidpublisherScope],
  );

  final api = AndroidPublisherApi(client);

  try {
    // 5. Create an Edit session
    stdout.writeln('==> Creating edit session for package: $packageName...');
    final appEdit = await api.edits.insert(AppEdit(), packageName);
    final editId = appEdit.id;
    if (editId == null) {
      stderr.writeln('Error: Failed to create edit session.');
      exit(1);
    }
    stdout.writeln('==> Edit session created (ID: $editId).');

    // 6. Upload App Bundle
    final fileSizeMb = (bundleFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    stdout.writeln('==> Uploading App Bundle ($fileSizeMb MB) to Google Play...');
    final media = Media(bundleFile.openRead(), bundleFile.lengthSync());
    final bundleResult = await api.edits.bundles.upload(
      packageName,
      editId,
      uploadMedia: media,
    );

    final int? versionCode = bundleResult.versionCode;
    stdout.writeln('==> Bundle uploaded successfully. Version Code: $versionCode');

    if (versionCode == null) {
      stderr.writeln('Error: Bundle uploaded but versionCode is null.');
      exit(1);
    }

    // 7. Configure Track & Release
    stdout.writeln('==> Assigning version $versionCode to track "$track" (status: $status)...');
    List<LocalizedText>? localizedReleaseNotes;
    if (releaseNotes != null && releaseNotes.isNotEmpty) {
      localizedReleaseNotes = [
        LocalizedText(language: 'en-US', text: releaseNotes),
      ];
    }

    double? userFraction;
    if (userFractionStr != null) {
      userFraction = double.tryParse(userFractionStr);
    }

    final release = TrackRelease(
      versionCodes: [versionCode.toString()],
      status: status,
      userFraction: userFraction,
      releaseNotes: localizedReleaseNotes,
    );

    final trackObj = Track(
      track: track,
      releases: [release],
    );

    await api.edits.tracks.update(
      trackObj,
      packageName,
      editId,
      track,
    );
    stdout.writeln('==> Track "$track" updated.');

    // 8. Commit the Edit
    stdout.writeln('==> Committing changes to Google Play Console...');
    final commitResult = await api.edits.commit(packageName, editId);
    stdout.writeln('==> Successfully published to Google Play Console!');
    stdout.writeln('    Package:     $packageName');
    stdout.writeln('    VersionCode: $versionCode');
    stdout.writeln('    Track:       $track');
    stdout.writeln('    Status:      $status');
    stdout.writeln('    Edit ID:     ${commitResult.id}');
  } catch (e) {
    stderr.writeln('');
    stderr.writeln('Error during Play Store publishing: $e');
    exit(1);
  } finally {
    client.close();
  }
}
