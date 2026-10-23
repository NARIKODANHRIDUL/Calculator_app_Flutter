import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aboutus.dart';
import 'package:in_app_update/in_app_update.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  binding.addPostFrameCallback((_) async {
    try {
      final context = binding.rootElement;
      if (context != null) {
        await precacheImage(const AssetImage("images/neriquest.png"), context);
      }
    } catch (_) {
      // Ignored if precache fails
    } finally {
      binding.allowFirstFrame();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: const Color(0xFF161922),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF161922),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.lightGreen,
          surface: Color(0xFF161922),
          onSurface: Colors.white,
          onSecondary: Color(0xFFC7CBD1),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  static String formatIndianExpression(String expr) => _HomeState.formatIndianExpression(expr);
  static int calculateFormattedCursor(String formatted, int targetRawIndex) => _HomeState.calculateFormattedCursor(formatted, targetRawIndex);
  static String formatIndianInteger(String intStr) => _HomeState.formatIndianInteger(intStr);
  static String formatResult(double val) => _HomeState.formatResult(val);

  @override
  State<Home> createState() => _HomeState();
}

class CalculatorTextEditingController extends TextEditingController {
  CalculatorTextEditingController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Return standard TextSpan with 1:1 length parity to controller.text,
    // ensuring caret and selection offsets never desynchronize.
    return TextSpan(text: text, style: style);
  }
}

class _HomeState extends State<Home> {
  late TextEditingController controller;
  late TextEditingController convertController;
  late ScrollController scrollController;
  late ScrollController scrollController1;

  String answer = '';
  int openBracket = 0;
  int closingBracket = 0;
  String strBfrCursor = '';
  int cursor = 0;
  String converterStrBfrCursor = '';
  int converterCursor = 0;
  String binaryValue = '0';
  String octalValue = '0';
  String decimalValue = '0';
  String hexValue = '0';
  String logx = "log₁₀";

  Color bgColor = const Color.fromARGB(255, 0, 0, 0);
  Color topBox = const Color.fromARGB(255, 16, 16, 16);
  Color resultColor = Colors.grey.shade200.withValues(alpha: 0.8);
  Color eqColor = Colors.grey.shade100;
  Color buttonColor = const Color.fromARGB(255, 14, 14, 14);
  bool isDark = true;
  int themeColorId = 1;
  List<List<String>> history = [];
  List<String> inputAnswer = [];

  double resultSize = 40;
  double eqSize = 50;

  double get dynamicResultSize {
    final double baseSize = (isEqual > 0 && isEqual % 2 == 1) ? 50.0 : 40.0;
    final int len = answer.length;
    if (len <= 9) return baseSize;
    if (len <= 14) {
      return baseSize - ((len - 9) * 1.8);
    }
    return (baseSize - 9.0).clamp(24.0, baseSize);
  }

  double get dynamicEqSize {
    if (isEqual > 0 && isEqual % 2 == 1) {
      return 24.0;
    }
    final int len = controller.text.replaceAll('\u200B', '').length;
    if (len <= 10) return 44.0;
    if (len <= 24) {
      return 44.0 - ((len - 10) * (16.0 / 14.0));
    }
    return 28.0;
  }
  int isEqual = 0;
  String dummyInput = '';

  String value = "Decimal";
  MaterialColor bTheme = Colors.lightGreen;
  static const divider = Divider(
    height: 8,
    thickness: 0,
    color: Colors.transparent,
  );

  String converterSelectedItem = 'Decimal';
  final List<String> converterItems = [
    'Binary',
    'Octal',
    'Decimal',
    'Hexadecimal'
  ];
  String logxSelected = 'log₁₀';
  final List<String> logxList = ['log₁₀', 'log₂', 'ln'];

  @override
  void initState() {
    super.initState();
    controller = CalculatorTextEditingController();
    convertController = TextEditingController();
    scrollController = ScrollController();
    scrollController1 = ScrollController();
    read();
    checkForUpdate();
  }

  @override
  void dispose() {
    controller.dispose();
    convertController.dispose();
    scrollController.dispose();
    scrollController1.dispose();
    super.dispose();
  }

  Future<void> checkForUpdate() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform != TargetPlatform.android) return;
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await update();
      }
    } catch (_) {
      // Ignored if update check fails
    }
  }

  Future<void> update() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
      // Ignored
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    await prefs.setInt('themeColorId', themeColorId);
    await saveHistory(history);
  }

  Future<void> read() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkVal = prefs.getBool('isDark') ?? true;
    final themeColorIdVal = prefs.getInt('themeColorId') ?? 1;
    final loadedHistory = await readHistory();
    if (!mounted) return;
    setState(() {
      isDark = isDarkVal;
      themeColorId = themeColorIdVal;
      history = loadedHistory;
    });
  }

  Future<void> saveHistory(List<List<String>> myList) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringList =
        myList.map((e) => "${e[0]};${e[1]};${e[2]}").toList();
    await prefs.setStringList('myListKey', stringList);
  }

  Future<List<List<String>>> readHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringList = prefs.getStringList('myListKey') ?? [];
    return stringList
        .map((e) => e.split(";"))
        .where((e) => e.length >= 3)
        .toList();
  }

  // ========================================================
  // Indian Style Comma Formatting Logic
  // ========================================================

  static String formatIndianInteger(String intStr) {
    if (intStr.length <= 3) return intStr;
    final String lastThree = intStr.substring(intStr.length - 3);
    String other = intStr.substring(0, intStr.length - 3);
    List<String> groups = [];
    while (other.length > 2) {
      groups.insert(0, other.substring(other.length - 2));
      other = other.substring(0, other.length - 2);
    }
    if (other.isNotEmpty) {
      groups.insert(0, other);
    }
    return '${groups.join(',')},$lastThree';
  }

  static String formatIndianNumberToken(String numStr) {
    if (numStr.isEmpty) return numStr;
    final dotIdx = numStr.indexOf('.');
    if (dotIdx == -1) {
      return formatIndianInteger(numStr);
    } else {
      final intPart = numStr.substring(0, dotIdx);
      final decPart = numStr.substring(dotIdx);
      return formatIndianInteger(intPart) + decPart;
    }
  }

  static String formatIndianExpression(String expr) {
    final clean = expr.replaceAll(',', '').replaceAll('\u200B', '');
    final formatted = clean.replaceAllMapped(RegExp(r'\d+(\.\d*)?|\.\d+'), (m) {
      return formatIndianNumberToken(m.group(0)!);
    });
    return formatted.replaceAllMapped(
      RegExp(r'(?<![\(\+–×\*÷/\-]|^)[\+–×\*÷/\-]'),
      (m) => '${m.group(0)}\u200B',
    );
  }

  static int calculateFormattedCursor(String formatted, int targetRawIndex) {
    if (targetRawIndex <= 0) return 0;
    int nonDecorSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != ',' && formatted[i] != '\u200B') {
        nonDecorSeen++;
        if (nonDecorSeen == targetRawIndex) {
          if (i + 1 < formatted.length && formatted[i + 1] == '\u200B') {
            return i + 2;
          }
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  @override
  Widget build(BuildContext context) {
    if (themeColorId == 1) {
      bTheme = Colors.lightGreen;
    } else if (themeColorId == 2) {
      bTheme = Colors.lightBlue;
    } else if (themeColorId == 3) {
      bTheme = Colors.red;
    } else {
      bTheme = Colors.orange;
    }

    final ColorScheme colorScheme = isDark
        ? ColorScheme.dark(
            primary: bTheme,
            secondary: bTheme.shade300,
            onSecondary: const Color(0xFFC7CBD1),
            surface: const Color(0xFF161922),
            onSurface: Colors.white,
          )
        : ColorScheme.light(
            primary: bTheme,
            secondary: bTheme.shade700,
            onSecondary: const Color(0xFF4A4E54),
            surface: Colors.white,
            onSurface: Colors.black,
          );

    if (isDark) {
      bgColor = const Color.fromARGB(255, 0, 0, 0);
      topBox = const Color(0xFF242832);
      resultColor = bTheme.shade300;
      eqColor = colorScheme.onSecondary;
      buttonColor = const Color(0xFF16181D);
    } else {
      bgColor = const Color.fromARGB(255, 235, 235, 238);
      topBox = Colors.white;
      resultColor = bTheme.shade700;
      eqColor = colorScheme.onSecondary;
      buttonColor = const Color(0xFFE8E9ED);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 7, bottom: 7),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.65),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 32,
                        padding: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? bTheme.shade200.withValues(alpha: 0.12)
                              : bTheme.shade200.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButton<String>(
                          iconEnabledColor: bTheme.shade300,
                          iconDisabledColor: bTheme.shade300,
                          borderRadius: BorderRadius.circular(16),
                          dropdownColor: isDark ? const Color(0xFF141414) : Colors.grey.shade200,
                          elevation: 15,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          items: logxList
                              .map((item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          style: TextStyle(
                            color: bTheme.shade300,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          underline: const SizedBox(),
                          value: logxSelected,
                          onChanged: (item) {
                            setState(() {
                              logxSelected = item ?? 'log₁₀';
                              logx = item ?? 'log₁₀';
                              if (item == "log₂") {
                                toastMsg("Log to the base 2");
                              } else if (item == "ln") {
                                toastMsg("Log(ln) to the base e");
                              } else if (item == "log₁₀") {
                                toastMsg("Log to the base 10");
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () {
                          isEqual = 0;
                          showConverter(context);
                        },
                        tooltip: "Converter",
                        splashRadius: 18,
                        icon: Icon(
                          Icons.swap_horiz_rounded,
                          size: 26,
                          color: bTheme.shade300,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () {
                          isEqual = 0;
                          showHistory(context);
                        },
                        tooltip: "History",
                        splashRadius: 18,
                        icon: Icon(
                          Icons.history,
                          size: 24,
                          color: bTheme.shade300,
                        ),
                      ),
                      PopupMenuButton<int>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        splashRadius: 18,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: bTheme.shade300,
                          size: 23,
                        ),
                        position: PopupMenuPosition.under,
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Theme",
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Icon(
                                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  color: bTheme.shade300,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: Text(
                              "About Us",
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 2,
                            child: Text(
                              "Share App",
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 3,
                            child: Text(
                              "Rate Us",
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        onSelected: (val) async {
                          if (val == 0) {
                            showTheme(MediaQuery.of(context).size.width, context);
                          } else if (val == 1) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    about(isDark: isDark),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 220),
                              ),
                            );
                          } else if (val == 2) {
                            Share.share(
                              "Check out Calculator App in Google PlayStore https://play.google.com/store/apps/details?id=neriquest.calculator",
                            );
                          } else if (val == 3) {
                            openUrl(
                              'https://play.google.com/store/apps/details?id=neriquest.calculator',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails details) {
          if (details.velocity.pixelsPerSecond.dy < 0) {
            isEqual = 0;
            showHistory(context);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;
            final double keypadWidth = screenWidth.clamp(0.0, 480.0);

            final double topAreaHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
            final double availableHeight = (screenHeight - topAreaHeight).clamp(200.0, screenHeight);

            // Dynamically scale button sizes to fit availableHeight without overflowing
            final double maxKeypadHeight = availableHeight * 0.68;
            final double defaultButtonSize = keypadWidth * 0.22;
            final double buttonSize = (defaultButtonSize * 5.5 + 56 > maxKeypadHeight)
                ? ((maxKeypadHeight - 56) / 5.5).clamp(28.0, defaultButtonSize)
                : defaultButtonSize;

            final double hGap = ((keypadWidth - buttonSize * 4) / 5).clamp(2.0, 20.0);
            final double extraButtonWidth = (keypadWidth - hGap * 6) / 5;
            final double extraButtonHeight = buttonSize * 0.45;

            final verticalDivider = SizedBox(width: hGap);
            final verticalDivider2 = SizedBox(width: hGap);

            final Color baseBoxColor = isDark ? const Color(0xFF0C0E14) : const Color(0xFFF3F5F8);
            final Color topGradientColor = Color.alphaBlend(
              bTheme.withValues(alpha: isDark ? 0.30 : 0.35),
              baseBoxColor,
            );

            return Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              topGradientColor,
                              baseBoxColor,
                              baseBoxColor,
                            ],
                            stops: const [0.0, 0.35, 1.0],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Input TextField: Only input box is scrollable, typing starts bottom right, autoscale then vertical scale
                              Expanded(
                                child: ScrollbarTheme(
                                  data: ScrollbarThemeData(
                                    thumbColor: WidgetStateProperty.all(bTheme.shade300.withValues(alpha: 0.65)),
                                    radius: const Radius.circular(8),
                                    thickness: WidgetStateProperty.all(3.5),
                                  ),
                                  child: Scrollbar(
                                    controller: scrollController,
                                    thumbVisibility: true,
                                    scrollbarOrientation: ScrollbarOrientation.right,
                                    child: ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        final double fadeHeight = topAreaHeight.clamp(20.0, bounds.height);
                                        final double stop = (fadeHeight / bounds.height).clamp(0.0, 1.0);
                                        return LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: const [
                                            Colors.transparent,
                                            Colors.transparent,
                                            Colors.white,
                                          ],
                                          stops: [
                                            0.0,
                                            stop * 0.4,
                                            stop,
                                          ],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            physics: const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics(),
                                            ),
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                              child: IntrinsicHeight(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    SizedBox(height: topAreaHeight),
                                                    const Spacer(),
                                                    AnimatedSize(
                                                      duration: const Duration(milliseconds: 240),
                                                      curve: Curves.easeOutCubic,
                                                      alignment: Alignment.bottomRight,
                                                      child: TextField(
                                                        onChanged: (changed) {
                                                          isEqual = 0;
                                                          // Handle pasting with auto Indian comma formatting
                                                          final String formatted = formatIndianExpression(changed);
                                                          if (formatted != changed) {
                                                            final int currentOffset = controller.selection.baseOffset.clamp(0, changed.length);
                                                            final int rawCur = changed.substring(0, currentOffset).replaceAll(',', '').replaceAll('\u200B', '').length;
                                                            final int newCur = calculateFormattedCursor(formatted, rawCur);
                                                            controller.value = TextEditingValue(
                                                              text: formatted,
                                                              selection: TextSelection.collapsed(offset: newCur.clamp(0, formatted.length)),
                                                            );
                                                          }
                                                          calculate(false);
                                                          scrollTheExpression();
                                                        },
                                                        onTap: () {
                                                          scrollTheExpression();
                                                        },
                                                        scrollPhysics: const NeverScrollableScrollPhysics(),
                                                        maxLines: null,
                                                        textAlign: TextAlign.right,
                                                        autofocus: true,
                                                        style: GoogleFonts.ubuntuMono(
                                                          fontSize: dynamicEqSize,
                                                          color: eqColor,
                                                          letterSpacing: -0.5,
                                                          height: 1.25,
                                                        ),
                                                        cursorColor: bTheme.shade300,
                                                        textDirection: TextDirection.ltr,
                                                        cursorRadius: const Radius.circular(12),
                                                        keyboardType: TextInputType.none,
                                                        controller: controller,
                                                        textInputAction: TextInputAction.previous,
                                                        decoration: const InputDecoration(
                                                          border: InputBorder.none,
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.only(right: 6, bottom: 4),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Answer display with bottom clearance for Scrollbar
                              Container(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Scrollbar(
                                  thumbVisibility: false,
                                  thickness: 3,
                                  scrollbarOrientation: ScrollbarOrientation.bottom,
                                  radius: const Radius.circular(8),
                                  controller: scrollController1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: scrollController1,
                                      child: GestureDetector(
                                        onLongPress: () async {
                                          if (answer.isNotEmpty) {
                                            await Clipboard.setData(
                                              ClipboardData(text: answer),
                                            );
                                            toastMsg("$answer copied to Clipboard");
                                          }
                                        },
                                        child: Text(
                                          answer,
                                          style: GoogleFonts.ubuntuMono(
                                            color: (answer == "Error" ||
                                                    answer == "Infinity" ||
                                                    answer == "-Infinity" ||
                                                    answer == "Keep it real")
                                                ? const Color.fromARGB(255, 252, 114, 63)
                                                : ((isEqual > 0 && isEqual % 2 == 1)
                                                    ? resultColor
                                                    : (isDark ? Colors.white60 : Colors.black45)),
                                            fontSize: dynamicResultSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
              ),
            ),
          ),
        ),
                SafeArea(
                  top: false,
                  child: Center(
                    child: SizedBox(
                      width: keypadWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          divider,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              verticalDivider2,
                              extraButton("√", extraButtonWidth, extraButtonHeight),
                              verticalDivider2,
                              extraButton("^", extraButtonWidth, extraButtonHeight),
                              verticalDivider2,
                              extraButton("!", extraButtonWidth, extraButtonHeight),
                              verticalDivider2,
                              extraButton("e", extraButtonWidth, extraButtonHeight),
                              verticalDivider2,
                              extraButton(logx, extraButtonWidth, extraButtonHeight),
                              verticalDivider2,
                            ],
                          ),
                          divider,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              mainButton("AC", buttonSize, hGap),
                              verticalDivider,
                              mainButton("()", buttonSize, hGap),
                              verticalDivider,
                              mainButton("÷", buttonSize, hGap),
                              verticalDivider,
                              mainButton('×', buttonSize, hGap),
                            ],
                          ),
                          divider,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              mainButton("7", buttonSize, hGap),
                              verticalDivider,
                              mainButton("8", buttonSize, hGap),
                              verticalDivider,
                              mainButton("9", buttonSize, hGap),
                              verticalDivider,
                              mainButton("–", buttonSize, hGap),
                            ],
                          ),
                          divider,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              mainButton("4", buttonSize, hGap),
                              verticalDivider,
                              mainButton("5", buttonSize, hGap),
                              verticalDivider,
                              mainButton("6", buttonSize, hGap),
                              verticalDivider,
                              mainButton("+", buttonSize, hGap),
                            ],
                          ),
                          divider,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              mainButton("1", buttonSize, hGap),
                              verticalDivider,
                              mainButton("2", buttonSize, hGap),
                              verticalDivider,
                              mainButton("3", buttonSize, hGap),
                              verticalDivider,
                              mainButton("D", buttonSize, hGap),
                            ],
                          ),
                          divider,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              mainButton(".", buttonSize, hGap),
                              verticalDivider,
                              mainButton("0", buttonSize, hGap),
                              verticalDivider,
                              mainButton("=", buttonSize, hGap),
                            ],
                          ),
                          divider,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget extraButton(String tag, double btnWidth, double btnHeight) {
    return MorphingCalculatorButton(
      width: btnWidth,
      height: btnHeight,
      elevation: 0,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      foregroundColor: bTheme.shade300,
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        width: 1,
      ),
      onLongPress: () {
        setState(() {
          if (tag == "log₁₀") {
            logx = "log₂";
            toastMsg("Log to the base 2");
            logxSelected = "log₂";
          } else if (tag == "log₂") {
            logx = "ln";
            toastMsg("Log(ln) to the base e");
            logxSelected = "ln";
          } else if (tag == "ln") {
            logx = "log₁₀";
            toastMsg("Log to the base 10");
            logxSelected = "log₁₀";
          }
        });
      },
      onPressed: () {
        setState(() {
          isEqual = 0;
          cursor = controller.selection.baseOffset;
          cursor = (cursor == -1 || cursor > controller.text.length)
              ? controller.text.length
              : cursor;
          strBfrCursor = controller.text.substring(0, cursor);

          if (tag == '√') {
            typeIt(controller, '√(');
          } else if (tag == '^') {
            final rawBfr = strBfrCursor.replaceAll(',', '').replaceAll('\u200B', '');
            if (rawBfr.isNotEmpty &&
                (isNum(rawBfr[rawBfr.length - 1]) ||
                    rawBfr.endsWith(')') ||
                    rawBfr.endsWith('!') ||
                    rawBfr.endsWith('e'))) {
              typeIt(controller, '^(');
            }
          } else if (tag == '!') {
            final rawBfr = strBfrCursor.replaceAll(',', '').replaceAll('\u200B', '');
            if (rawBfr.isNotEmpty &&
                (isNum(rawBfr[rawBfr.length - 1]) ||
                    rawBfr.endsWith(')'))) {
              typeIt(controller, '!');
            }
          } else if (tag == 'e') {
            if (strBfrCursor.replaceAll('\u200B', '').endsWith("√")) {
              typeIt(controller, '(e');
            } else {
              typeIt(controller, 'e');
            }
          } else if (tag == 'log₂') {
            if (strBfrCursor.replaceAll('\u200B', '').endsWith("√")) {
              typeIt(controller, '(㏒₂(');
            } else {
              typeIt(controller, "㏒₂(");
            }
          } else if (tag == 'log₁₀') {
            if (strBfrCursor.replaceAll('\u200B', '').endsWith("√")) {
              typeIt(controller, '(㏒(');
            } else {
              typeIt(controller, '㏒(');
            }
          } else if (tag == 'ln') {
            if (strBfrCursor.replaceAll('\u200B', '').endsWith("√")) {
              typeIt(controller, '(㏑(');
            } else {
              typeIt(controller, '㏑(');
            }
          }

          if (answer != '') {
            eqSize = 50;
            resultSize = 40;
          }
        });

        calculate(false);
        scrollTheExpression(strBfrCursor);
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: tag == '^'
              ? EdgeInsets.only(top: btnHeight * 0.2)
              : const EdgeInsets.all(0),
          child: Transform.scale(
            scale: (tag == "log₁₀")
                ? 0.90
                : (tag == "log₂")
                    ? 1.05
                    : (tag == "ln")
                        ? 1.05
                        : 1.0,
            child: Text(
              tag,
              style: GoogleFonts.ubuntuMono(
                fontSize: (tag == "log₁₀") ? 16 : 20,
                fontWeight: FontWeight.w500,
                color: bTheme.shade300,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mainButton(String tag, double buttonSize, double hGap) {
    final double buttonWidth = tag == "=" ? (buttonSize * 2 + hGap) : buttonSize;

    final Color fgColor = (isOperator(tag) || tag == '='
        ? isDark
            ? Colors.grey.shade900
            : Colors.grey.shade100
        : bTheme.shade300);

    final Color bgColor = (isOperator(tag) || tag == '='
        ? isDark
            ? bTheme.shade300.withValues(alpha: 0.85)
            : bTheme.shade300.withValues(alpha: 0.75)
        : buttonColor);

    return MorphingCalculatorButton(
      width: buttonWidth,
      height: buttonSize,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: (isOperator(tag) || tag == '=') ? 4 : 2,
      borderSide: BorderSide(
        color: (isOperator(tag) || tag == '=')
            ? Colors.white.withValues(alpha: isDark ? 0.25 : 0.45)
            : (isDark
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.white.withValues(alpha: 0.70)),
        width: 1,
      ),
      onLongPress: () {
        if (tag == 'D') {
          setState(() {
            isEqual = 0;
            cursor = controller.selection.baseOffset;
            cursor = (cursor == -1 || cursor > controller.text.length)
                ? controller.text.length
                : cursor;
            controller.text = formatIndianExpression(controller.text.substring(cursor));
            freezeCursor(controller, 1);
          });
          calculate(false);
        }
      },
      onPressed: () {
        setState(() {
          cursor = controller.selection.baseOffset;
          cursor = (cursor == -1 || cursor > controller.text.length)
              ? controller.text.length
              : cursor;
          strBfrCursor = controller.text.substring(0, cursor);
          final String rawBfrCursor = strBfrCursor.replaceAll(',', '').replaceAll('\u200B', '');

          if (answer != '') {
            eqSize = 50;
            resultSize = 40;
          }

          if (tag == 'AC') {
            controller.text = '';
            answer = '';
          } else if (tag == 'D') {
            // Intelligent backspace with Indian Comma System:
            // Deletes the digit/symbol before comma instead of dangling comma
            if (controller.text.isNotEmpty && cursor > 0) {
              final int rawCur = controller.text.substring(0, cursor).replaceAll(',', '').replaceAll('\u200B', '').length;
              if (rawCur > 0) {
                int deleteCount = 1;
                if (rawBfrCursor.endsWith('㏒₂(')) {
                  deleteCount = 3;
                } else if (rawBfrCursor.endsWith('㏒(') ||
                    rawBfrCursor.endsWith('㏑(') ||
                    rawBfrCursor.endsWith('^(') ||
                    rawBfrCursor.endsWith('√(')) {
                  deleteCount = 2;
                }
                deleteCount = deleteCount.clamp(1, rawCur);

                final String clean = controller.text.replaceAll(',', '').replaceAll('\u200B', '');
                final String newClean = clean.substring(0, rawCur - deleteCount) + clean.substring(rawCur);
                final int targetRawCur = rawCur - deleteCount;

                final String formatted = formatIndianExpression(newClean);
                final int newCur = calculateFormattedCursor(formatted, targetRawCur);

                controller.text = formatted;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: newCur));
              }
            }
          } else if (tag == '=') {
            if (controller.text.trim().isNotEmpty) {
              isEqual += 1;
              if (isEqual % 2 == 1) {
                if (isEqual > 2 && dummyInput.isNotEmpty) {
                  controller.text = dummyInput;
                }
                calculate(true);
                dummyInput = controller.text;
                eqSize = 40;
                resultSize = 50;
                if (answer.isNotEmpty &&
                    answer != 'Error' &&
                    answer != 'Keep it real' &&
                    answer != 'Infinity' &&
                    answer != '-Infinity') {
                  if (history.isEmpty || history.last[0] != controller.text) {
                    final now = DateTime.now();
                    final formattedDate =
                        '${now.day} ${getMonthName(now.month)} ${now.year}, ${getFormattedTime(now.hour, now.minute)}';
                    inputAnswer = [
                      controller.text,
                      answer,
                      formattedDate,
                    ];
                    history.add(inputAnswer);
                    save();
                  }
                }
              } else {
                if (answer.isNotEmpty &&
                    answer != 'Error' &&
                    answer != 'Keep it real' &&
                    answer != 'Infinity' &&
                    answer != '-Infinity') {
                  controller.text = formatIndianExpression(answer);
                  freezeCursor(controller, controller.text.length + 1);
                }
                eqSize = 50;
                resultSize = 40;
              }
            } else {
              answer = '';
              toastMsg("Type Some expression and try");
            }
          } else if (tag == '()') {
            openBracket = rawBfrCursor.split("(").length - 1;
            closingBracket = rawBfrCursor.split(")").length - 1;

            if (openBracket == closingBracket ||
                rawBfrCursor.endsWith('+') ||
                rawBfrCursor.endsWith("–") ||
                rawBfrCursor.endsWith("-") ||
                rawBfrCursor.endsWith("×") ||
                rawBfrCursor.endsWith("*") ||
                rawBfrCursor.endsWith("÷") ||
                rawBfrCursor.endsWith("/") ||
                rawBfrCursor.endsWith("(") ||
                rawBfrCursor.isEmpty) {
              typeIt(controller, '(');
            } else if (openBracket > closingBracket) {
              typeIt(controller, ')');
            } else {
              typeIt(controller, '(');
            }
          } else if (tag == '–') {
            if (rawBfrCursor.endsWith('–') || rawBfrCursor.endsWith('-')) {
              toastMsg("Invalid Input");
            } else if (rawBfrCursor.endsWith('÷') ||
                rawBfrCursor.endsWith('/') ||
                rawBfrCursor.endsWith('×') ||
                rawBfrCursor.endsWith('*') ||
                rawBfrCursor.endsWith('+')) {
              // Replace preceding operator
              final int rawCur = controller.text.substring(0, cursor).replaceAll(',', '').replaceAll('\u200B', '').length;
              if (rawCur > 0) {
                final String clean = controller.text.replaceAll(',', '').replaceAll('\u200B', '');
                final String newClean = '${clean.substring(0, rawCur - 1)}–${clean.substring(rawCur)}';
                final String formatted = formatIndianExpression(newClean);
                final int newCur = calculateFormattedCursor(formatted, rawCur);
                controller.text = formatted;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: newCur));
              }
            } else {
              typeIt(controller, '–');
            }
          } else if (isNum(tag) || tag == '.') {
            if (tag == '.') {
              if (rawBfrCursor.endsWith(')')) {
                toastMsg("Invalid Input");
              } else if (rawBfrCursor.endsWith('.')) {
                toastMsg("Invalid Input");
              } else {
                final int lastOp = rawBfrCursor.lastIndexOf(RegExp(r'[\+\–\-\×\*\÷\/\(\^\√]'));
                final String currentNum = lastOp == -1
                    ? rawBfrCursor
                    : rawBfrCursor.substring(lastOp + 1);
                if (currentNum.contains('.')) {
                  toastMsg("Invalid Input");
                } else {
                  if (rawBfrCursor.isEmpty ||
                      rawBfrCursor.endsWith('+') ||
                      rawBfrCursor.endsWith('–') ||
                      rawBfrCursor.endsWith('-') ||
                      rawBfrCursor.endsWith('×') ||
                      rawBfrCursor.endsWith('*') ||
                      rawBfrCursor.endsWith('÷') ||
                      rawBfrCursor.endsWith('/') ||
                      rawBfrCursor.endsWith('(')) {
                    typeIt(controller, '0.');
                  } else {
                    typeIt(controller, '.');
                  }
                }
              }
            } else {
              typeIt(controller, tag);
            }
          } else {
            // Operators +, ×, ÷
            if (rawBfrCursor != '–' &&
                rawBfrCursor != '-' &&
                !rawBfrCursor.endsWith('(–') &&
                !rawBfrCursor.endsWith('(-') &&
                rawBfrCursor.isNotEmpty &&
                (rawBfrCursor.endsWith('÷') ||
                    rawBfrCursor.endsWith('/') ||
                    rawBfrCursor.endsWith('×') ||
                    rawBfrCursor.endsWith('*') ||
                    rawBfrCursor.endsWith('–') ||
                    rawBfrCursor.endsWith('-') ||
                    rawBfrCursor.endsWith('+'))) {
              final int rawCur = controller.text.substring(0, cursor).replaceAll(',', '').replaceAll('\u200B', '').length;
              final String clean = controller.text.replaceAll(',', '').replaceAll('\u200B', '');
              final String newClean = clean.substring(0, rawCur - 1) + tag + clean.substring(rawCur);
              final String formatted = formatIndianExpression(newClean);
              final int newCur = calculateFormattedCursor(formatted, rawCur);
              controller.text = formatted;
              controller.selection = TextSelection.fromPosition(TextPosition(offset: newCur));
            } else if (rawBfrCursor.isNotEmpty &&
                (isNum(rawBfrCursor[rawBfrCursor.length - 1]) ||
                    rawBfrCursor.endsWith(')') ||
                    rawBfrCursor.endsWith('!') ||
                    rawBfrCursor.endsWith('e'))) {
              typeIt(controller, tag);
            } else {
              toastMsg("Invalid Input");
            }
          }
        });

        if (tag != '=') {
          isEqual = 0;
          calculate(false);
        }

        scrollTheExpression(strBfrCursor);
      },
      child: Center(
        child: tag == 'D'
            ? Icon(
                Icons.backspace,
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                size: buttonSize * 0.34,
              )
            : (tag == '×'
                ? Icon(
                    Icons.close,
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    size: buttonSize * 0.34,
                  )
                : (tag == '+'
                    ? Icon(
                        Icons.add,
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        size: buttonSize * 0.34,
                      )
                    : (tag == '–'
                        ? Icon(
                            Icons.horizontal_rule_rounded,
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            size: buttonSize * 0.34,
                          )
                        : FittedBox(
                            child: Padding(
                              padding: tag == '.'
                                  ? EdgeInsets.only(bottom: buttonSize * 0.2)
                                  : const EdgeInsets.all(0),
                              child: Text(
                                tag,
                                style: (tag == '÷')
                                    ? GoogleFonts.notoSansMono(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w300,
                                        color: fgColor,
                                      )
                                    : GoogleFonts.ubuntuMono(
                                        fontSize: (tag == '=' || tag == '.')
                                            ? 42
                                            : (tag == '()' || tag == 'AC')
                                                ? 28
                                                : 32,
                                        fontWeight: FontWeight.w500,
                                        color: fgColor,
                                      ),
                              ),
                            ),
                          )))),
      ),
    );
  }

  void showTheme(double wid, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            elevation: 20,
            backgroundColor: isDark
                ? const Color(0xFF161922).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.94),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1.5,
                color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(28.0)),
            ),
          title: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "THEME",
                  style: GoogleFonts.abel(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 15),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: ElevatedButton(
                    onPressed: () {
                      save();
                      setState(() {
                        isDark = !isDark;
                      });
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0),
                      fixedSize: const Size(60, 60),
                      elevation: 10,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : const Color.fromARGB(255, 200, 200, 200),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? bTheme.shade300 : Colors.grey.shade800,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.all(0),
          titlePadding: const EdgeInsets.only(top: 20, bottom: 10),
          insetPadding: const EdgeInsets.all(16),
          actionsPadding: const EdgeInsets.all(12),
          actions: [
            FittedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      themeButton(wid, "Green", ctx),
                      const SizedBox(width: 12),
                      themeButton(wid, "Blue", ctx),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      themeButton(wid, "Red", ctx),
                      const SizedBox(width: 12),
                      themeButton(wid, "Orange", ctx),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
      },
    );
  }

  Widget themeButton(double wid, String colorName, BuildContext ctx) {
    final double size = (wid * 0.35).clamp(80.0, 130.0);
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: SizedBox(
        height: size,
        width: size,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            backgroundColor: (colorName == "Green")
                ? Colors.lightGreen.shade300
                : (colorName == "Blue")
                    ? Colors.lightBlue.shade200
                    : (colorName == "Red")
                        ? Colors.redAccent.shade100
                        : Colors.orange.shade300,
          ),
          onPressed: () {
            save();
            setState(() {
              if (colorName == "Green") {
                themeColorId = 1;
              } else if (colorName == "Blue") {
                themeColorId = 2;
              } else if (colorName == "Red") {
                themeColorId = 3;
              } else {
                themeColorId = 4;
              }
            });
            Navigator.of(ctx).pop();
          },
          child: Text(
            colorName.toUpperCase(),
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: (colorName == "Green")
                  ? Colors.lightGreen.shade800
                  : (colorName == "Blue")
                      ? Colors.lightBlue.shade800
                      : (colorName == "Red")
                          ? Colors.redAccent.shade700
                          : Colors.orange.shade900,
            ),
          ),
        ),
      ),
    );
  }

  void calculate(bool pressed) {
    if (controller.text.trim().isEmpty) {
      setState(() {
        answer = '';
      });
      return;
    }

    // Strip Indian commas and ZWSP before math expression evaluation
    String userInput = controller.text.replaceAll(',', '').replaceAll('\u200B', '');

    // Ignore trailing operators for preview
    while (userInput.isNotEmpty &&
        (userInput.endsWith('÷') ||
            userInput.endsWith('×') ||
            userInput.endsWith('–') ||
            userInput.endsWith('-') ||
            userInput.endsWith('+') ||
            userInput.endsWith('*') ||
            userInput.endsWith('/') ||
            userInput.endsWith('√') ||
            userInput.endsWith('^'))) {
      userInput = userInput.substring(0, userInput.length - 1);
    }

    if (userInput.isEmpty) {
      setState(() {
        answer = pressed ? 'Error' : '';
      });
      return;
    }

    // Auto-close open brackets
    final int openCount = userInput.split("(").length - 1;
    final int closeCount = userInput.split(")").length - 1;
    if (openCount > closeCount && userInput != '(') {
      userInput += ')' * (openCount - closeCount);
    }

    // Replace operator symbols
    userInput = userInput.replaceAll('×', '*');
    userInput = userInput.replaceAll('÷', '/');
    userInput = userInput.replaceAll('–', '-');
    userInput = userInput.replaceAll(')(', ')*(');

    // Convert log representations
    userInput = userInput.replaceAllMapped(
        RegExp(r'㏒₂\(([^)]+)\)'), (m) => 'log(2, ${m.group(1)})');
    userInput = userInput.replaceAllMapped(
        RegExp(r'㏒\(([^)]+)\)'), (m) => 'log(10, ${m.group(1)})');
    userInput = userInput.replaceAll('㏑', 'ln');

    // Handle square roots
    userInput = userInput.replaceAllMapped(
        RegExp(r'(\d+|\))\s*√'), (m) => '${m.group(1)}*√');
    userInput = userInput.replaceAllMapped(
        RegExp(r'√\(([^)]+)\)'), (m) => 'sqrt(${m.group(1)})');
    userInput = userInput.replaceAllMapped(
        RegExp(r'√(\d+(\.\d+)?)'), (m) => 'sqrt(${m.group(1)})');
    userInput = userInput.replaceAllMapped(
        RegExp(r'√([a-zA-Z]+)'), (m) => 'sqrt(${m.group(1)})');
    userInput = userInput.replaceAll('√', 'sqrt');

    // Implied multiplication
    userInput = userInput.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?)\('), (m) => '${m.group(1)}*(');
    userInput = userInput.replaceAllMapped(
        RegExp(r'\)(\d+(\.\d+)?)'), (m) => ')*${m.group(1)}');
    userInput = userInput.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?)(log|ln|sqrt)'),
        (m) => '${m.group(1)}*${m.group(3)}');
    userInput = userInput.replaceAllMapped(
        RegExp(r'!(\d+|\(|log|ln|sqrt)'), (m) => '!*${m.group(1)}');

    // Euler's constant 'e'
    userInput = userInput.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?|\))e'), (m) => '${m.group(1)}*e');
    userInput = userInput.replaceAllMapped(
        RegExp(r'e(\d+|\(|log|ln|sqrt)'), (m) => 'e^1*${m.group(1)}');
    userInput = userInput.replaceAllMapped(
        RegExp(r'e(?!\^)'), (m) => 'e^1');

    userInput = userInput.replaceAll('(*', '(');
    if (userInput.startsWith('*')) {
      userInput = userInput.substring(1);
    }

    try {
      final Parser p = Parser();
      final Expression exp = p.parse(userInput);
      final ContextModel cm = ContextModel();
      final double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        if (eval.isNaN) {
          answer = 'Keep it real';
        } else if (eval == double.infinity) {
          answer = 'Infinity';
        } else if (eval == double.negativeInfinity) {
          answer = '-Infinity';
        } else {
          answer = formatResult(eval);
        }

        if (!pressed && controller.text.replaceAll('\u200B', '') == answer.replaceAll('\u200B', '')) {
          answer = '';
        }
      });
    } catch (_) {
      setState(() {
        if (pressed) {
          answer = 'Error';
        } else {
          answer = '';
        }
      });
    }
  }

  static String formatResult(double val) {
    if (val.isNaN) return 'Keep it real';
    if (val == double.infinity) return 'Infinity';
    if (val == double.negativeInfinity) return '-Infinity';
    if (val == 0.0 || val == -0.0) return '0';

    final absVal = val.abs();

    // If magnitude exceeds 1e9 (10+ digits) or is very small (< 1e-6), use scientific notation e
    if (absVal >= 1e9 || absVal < 1e-6) {
      return formatScientific(val);
    }

    // Integer handling (< 1e9)
    if (val == val.roundToDouble()) {
      final intInt = val.toInt();
      final sign = intInt < 0 ? '-' : '';
      final absStr = intInt.abs().toString();
      return sign + formatIndianInteger(absStr);
    }

    // Decimal number (< 1e9)
    final sign = val < 0 ? '-' : '';
    final intPart = absVal.floor();
    final intFormatted = formatIndianInteger(intPart.toString());

    // Calculate remaining character budget for decimals (target max width ~11 chars)
    final int availableDecimals = 11 - sign.length - intFormatted.length - 1; // -1 for '.'
    if (availableDecimals <= 0) {
      final rounded = val.round();
      final rSign = rounded < 0 ? '-' : '';
      return rSign + formatIndianInteger(rounded.abs().toString());
    }

    final clampedPrecision = availableDecimals.clamp(1, 8);
    String fixed = absVal.toStringAsFixed(clampedPrecision);
    fixed = removeTrailingZeros(fixed);

    final dotIdx = fixed.indexOf('.');
    if (dotIdx == -1) {
      return sign + formatIndianInteger(fixed);
    }

    final decPart = fixed.substring(dotIdx);
    return sign + intFormatted + decPart;
  }

  static String formatScientific(double val) {
    // Get initial exponent to decide precision
    final initialExpStr = val.toStringAsExponential();
    final expParts = initialExpStr.toLowerCase().split('e');
    final int expMag = expParts.length > 1 ? (int.tryParse(expParts[1])?.abs() ?? 0) : 0;

    // Reduce decimal precision offset based on exponent magnitude:
    // - 1-digit exponent (< 10): 6 decimals
    // - 2-digit exponent (10..99): 5 decimals
    // - 3-digit exponent (>= 100): 4 decimals
    int precision = 5;
    if (expMag >= 100) {
      precision = 4;
    } else if (expMag < 10) {
      precision = 6;
    }

    // If negative, reduce precision by 1 to accommodate the minus sign within screen width
    if (val < 0 && precision > 3) {
      precision -= 1;
    }

    final expStr = val.toStringAsExponential(precision);
    final parts = expStr.toLowerCase().split('e');
    final mantissa = removeTrailingZeros(parts[0]);
    return '${mantissa}e${parts[1]}';
  }

  static String removeTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    int i = value.length - 1;
    while (i >= 0 && value[i] == '0') {
      i--;
    }
    if (i >= 0 && value[i] == '.') {
      i--;
    }
    return value.substring(0, i + 1);
  }

  void convert(StateSetter setttState) {
    setttState(() {
      String text = convertController.text
          .trim()
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .replaceAll('_', '');

      if (text.isEmpty) {
        binaryValue = '0';
        decimalValue = '0';
        octalValue = '0';
        hexValue = '0';
        return;
      }

      int radix = 10;
      if (converterSelectedItem == 'Binary') {
        radix = 2;
        if (text.toLowerCase().startsWith('0b')) {
          text = text.substring(2);
        }
      } else if (converterSelectedItem == 'Octal') {
        radix = 8;
        if (text.toLowerCase().startsWith('0o')) {
          text = text.substring(2);
        }
      } else if (converterSelectedItem == 'Decimal') {
        radix = 10;
      } else if (converterSelectedItem == 'Hexadecimal') {
        radix = 16;
        if (text.toLowerCase().startsWith('0x')) {
          text = text.substring(2);
        }
      }

      if (text.isEmpty) {
        binaryValue = '0';
        decimalValue = '0';
        octalValue = '0';
        hexValue = '0';
        return;
      }

      final BigInt? number = BigInt.tryParse(text, radix: radix);
      if (number != null) {
        binaryValue = number.toRadixString(2);
        octalValue = number.toRadixString(8);
        decimalValue = formatIndianInteger(number.toRadixString(10));
        hexValue = number.toRadixString(16).toUpperCase();
      } else {
        binaryValue = 'Invalid';
        octalValue = 'Invalid';
        decimalValue = 'Invalid';
        hexValue = 'Invalid';
      }
    });
  }

  bool isOperator(String val) {
    return val == 'AC' ||
        val == 'D' ||
        val == '()' ||
        val == '÷' ||
        val == '/' ||
        val == '×' ||
        val == '*' ||
        val == '–' ||
        val == '-' ||
        val == '+';
  }

  bool isNum(String val) {
    return val.length == 1 &&
        val.codeUnitAt(0) >= 48 &&
        val.codeUnitAt(0) <= 57;
  }

  void typeIt(TextEditingController control, String str) {
    int cur = control.selection.baseOffset;
    cur = (cur == -1 || cur > control.text.length) ? control.text.length : cur;
    cur = cur.clamp(0, control.text.length);

    // Count non-comma, non-ZWSP characters before cursor
    final int rawCursor = control.text.substring(0, cur).replaceAll(',', '').replaceAll('\u200B', '').length;
    final String clean = control.text.replaceAll(',', '').replaceAll('\u200B', '');
    final String newClean = clean.substring(0, rawCursor) + str + clean.substring(rawCursor);
    final int targetRawCursor = rawCursor + str.length;

    final String formatted = formatIndianExpression(newClean);
    final int newCursor = calculateFormattedCursor(formatted, targetRawCursor);

    control.text = formatted;
    control.selection = TextSelection.fromPosition(TextPosition(offset: newCursor));
  }

  Future<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        toastMsg('Could not open link');
      }
    } catch (_) {
      toastMsg('Could not open link');
    }
  }

  void freezeCursor(TextEditingController control, int cur) {
    final int target = (cur - 1).clamp(0, control.text.length);
    control.selection =
        TextSelection.fromPosition(TextPosition(offset: target));
  }

  void toastMsg(String h) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: h);
  }

  String getBasePrefix(String system) {
    if (system == 'Hexadecimal') return '0x';
    if (system == 'Binary') return '0b';
    if (system == 'Octal') return '0o';
    return '';
  }

  void showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.55,
                maxChildSize: 0.88,
                minChildSize: 0.28,
                builder: (context, sheetScrollController) => Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1D24).withValues(alpha: 0.84)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.20)
                            : Colors.white,
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Drag indicator handle
                      Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Centered Header Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: SizedBox(
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'History',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 32,
                                      color: bTheme.shade300,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: bTheme.shade300.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: bTheme.shade300.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${history.length}',
                                      style: GoogleFonts.ubuntuMono(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: bTheme.shade300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (history.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      deleteHistory(context, -1);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.red.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.delete_sweep_rounded,
                                            size: 16,
                                            color: Colors.red.shade300,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Clear',
                                            style: GoogleFonts.nunito(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.red.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Divider(
                      height: 12,
                      thickness: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    // List
                    Expanded(
                      child: history.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off_rounded,
                                      size: 56,
                                      color: bTheme.shade300.withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      "No Calculation History",
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Your calculations and results will appear here",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      "End of History",
                                      style: GoogleFonts.ubuntuMono(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: bTheme.shade300.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: sheetScrollController,
                              padding: const EdgeInsets.only(top: 4, bottom: 24),
                              itemCount: history.length + 1,
                              itemBuilder: (context, index) {
                                if (index == history.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: Text(
                                        "End of History",
                                        style: GoogleFonts.ubuntuMono(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: bTheme.shade300.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final int itemIdx = history.length - 1 - index;
                                return historyListItem(itemIdx);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Future<dynamic> deleteHistory(BuildContext context, int index) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      enableDrag: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF12141A).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                  width: 1.2,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (index == -1) ? "Clear All History?" : "Delete Calculation?",
                                style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                (index == -1)
                                    ? "This will remove all saved calculations permanently."
                                    : "This item will be removed from your history list.",
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (index == -1) {
                                  history.clear();
                                } else if (index >= 0 && index < history.length) {
                                  history.removeAt(index);
                                }
                              });
                              save();
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop();
                              showHistory(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              (index == -1) ? "Clear All" : "Delete",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget historyListItem(int i) {
    final item = history[i];
    final Color timeColor = isDark
        ? const Color(0xFFC7CBD1).withValues(alpha: 0.65)
        : const Color(0xFF4A4E54).withValues(alpha: 0.70);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              controller.text = formatIndianExpression(item[0]);
              freezeCursor(controller, controller.text.length + 1);
            });
            Navigator.of(context).pop();
            calculate(false);
            scrollTheExpression();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        bTheme.shade400.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        bTheme.shade100.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.80),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.90),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left content: Expression, Result, Timestamp (bottom-left)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item[0],
                        style: GoogleFonts.ubuntuMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          item[1],
                          style: GoogleFonts.ubuntuMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: bTheme.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 10,
                            color: timeColor,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            item[2],
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: timeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right actions: Delete & Copy buttons (soft, low-contrast)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        deleteHistory(context, i);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: isDark ? 0.08 : 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: isDark ? 0.20 : 0.14),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: (isDark ? Colors.red.shade200 : Colors.red.shade400).withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await Clipboard.setData(ClipboardData(text: item[1]));
                        toastMsg("${item[1]} copied to Clipboard");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: bTheme.shade300.withValues(alpha: isDark ? 0.10 : 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: bTheme.shade300.withValues(alpha: isDark ? 0.22 : 0.18),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: bTheme.shade300.withValues(alpha: 0.80),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Copy",
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: bTheme.shade300.withValues(alpha: 0.80),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showConverter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setttState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1D24).withValues(alpha: 0.84)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : Colors.white,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              // Drag handle indicator
                              Container(
                                width: 38,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.28)
                                      : Colors.black.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Centered Header Bar
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: SizedBox(
                                  height: 68,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Converter',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.nunito(
                                              fontSize: 32,
                                              color: bTheme.shade300,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            'Base-2, 8, 10 & 16 Number Conversion',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(
                                height: 12,
                                thickness: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                              // Segmented TabBar
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: DefaultTabController(
                                  length: converterItems.length,
                                  initialIndex: converterItems.indexOf(converterSelectedItem),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.06),
                                        width: 1,
                                      ),
                                    ),
                                    child: TabBar(
                                      onTap: (index) {
                                        HapticFeedback.lightImpact();
                                        setttState(() {
                                          converterSelectedItem = converterItems[index];
                                          convertController.text = '';
                                          convert(setttState);
                                        });
                                      },
                                      indicator: BoxDecoration(
                                        color: bTheme.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      dividerColor: Colors.transparent,
                                      labelColor: isDark ? Colors.grey.shade900 : Colors.white,
                                      unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      labelStyle: GoogleFonts.nunito(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      unselectedLabelStyle: GoogleFonts.nunito(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      tabs: converterItems.map((item) => Tab(
                                        height: 36,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(item),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              // Modern Input Card (Fixed Height 56px)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Container(
                                  height: 56,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.80),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: bTheme.shade300.withValues(alpha: 0.50),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: bTheme.shade300.withValues(alpha: 0.10),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      if (getBasePrefix(converterSelectedItem).isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(top: 1.2),
                                          child: Text(
                                            getBasePrefix(converterSelectedItem),
                                            style: GoogleFonts.ubuntuMono(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: bTheme.shade300,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: TextField(
                                          controller: convertController,
                                          onChanged: (_) => convert(setttState),
                                          style: GoogleFonts.ubuntuMono(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          cursorColor: bTheme.shade300,
                                          cursorRadius: const Radius.circular(8),
                                          maxLines: 1,
                                          textAlign: TextAlign.left,
                                          keyboardType: TextInputType.none,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            hintText: converterSelectedItem == 'Decimal' ? '0' : '',
                                            hintStyle: GoogleFonts.ubuntuMono(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Modern Keypad
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      hexButton(context, '0', setttState),
                                      hexButton(context, '1', setttState),
                                      if (converterSelectedItem == "Binary")
                                        hexButton(context, 'AC', setttState),
                                      if (converterSelectedItem == "Binary")
                                        hexButton(context, 'DE', setttState),
                                      if (converterSelectedItem != "Binary")
                                        hexButton(context, '2', setttState),
                                      if (converterSelectedItem != "Binary")
                                        hexButton(context, '3', setttState),
                                      if (converterSelectedItem != "Binary")
                                        hexButton(context, '4', setttState),
                                      if (converterSelectedItem != "Binary" &&
                                          converterSelectedItem != "Octal")
                                        hexButton(context, '5', setttState),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (converterSelectedItem == "Octal")
                                        hexButton(context, '5', setttState),
                                      if (converterSelectedItem != "Binary")
                                        hexButton(context, '6', setttState),
                                      if (converterSelectedItem != "Binary")
                                        hexButton(context, '7', setttState),
                                      if (converterSelectedItem == "Octal")
                                        hexButton(context, 'AC', setttState),
                                      if (converterSelectedItem == "Octal")
                                        hexButton(context, 'DE', setttState),
                                      if (converterSelectedItem != "Binary" &&
                                          converterSelectedItem != "Octal")
                                        hexButton(context, '8', setttState),
                                      if (converterSelectedItem != "Binary" &&
                                          converterSelectedItem != "Octal")
                                        hexButton(context, '9', setttState),
                                      if (converterSelectedItem == "Decimal")
                                        hexButton(context, 'AC', setttState),
                                      if (converterSelectedItem == "Decimal")
                                        hexButton(context, 'DE', setttState),
                                      if (converterSelectedItem != "Binary" &&
                                          converterSelectedItem != "Octal" &&
                                          converterSelectedItem != "Decimal")
                                        hexButton(context, 'A', setttState),
                                      if (converterSelectedItem != "Binary" &&
                                          converterSelectedItem != "Octal" &&
                                          converterSelectedItem != "Decimal")
                                        hexButton(context, 'B', setttState),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (converterSelectedItem == "Hexadecimal")
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        hexButton(context, 'C', setttState),
                                        hexButton(context, 'D', setttState),
                                        hexButton(context, 'E', setttState),
                                        hexButton(context, 'F', setttState),
                                        hexButton(context, 'AC', setttState),
                                        hexButton(context, 'DE', setttState),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Result cards for the other 3 bases
                            for (int i = 0; i < 4; i++)
                              if (converterItems[i] != converterSelectedItem)
                                convertedListItem(converterItems[i], context),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget hexButton(
      BuildContext context, String hex, StateSetter setttState) {
    return SizedBox(
      height: 48,
      width: 48,
      child: MorphingCalculatorButton(
        width: 48,
        height: 48,
        elevation: 2,
        backgroundColor: (hex == 'DE' || hex == 'AC')
            ? bTheme.shade100.withValues(alpha: 0.35)
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        foregroundColor: (hex == 'DE' || hex == 'AC')
            ? (isDark ? bTheme.shade200 : bTheme.shade800)
            : (isDark ? Colors.grey.shade100 : Colors.grey.shade900),
        borderSide: BorderSide(
          color: (hex == 'DE' || hex == 'AC')
              ? bTheme.shade300.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black12),
          width: 1,
        ),
        onLongPress: () {
          if (hex == 'DE') {
            setttState(() {
              convertController.text = '';
              convert(setttState);
            });
          }
        },
        onPressed: () {
          setttState(() {
            converterCursor = convertController.selection.baseOffset;
            converterCursor = (converterCursor == -1 ||
                    converterCursor > convertController.text.length)
                ? convertController.text.length
                : converterCursor;

            if (hex == "AC") {
              convertController.text = '';
            } else if (hex == 'DE') {
              if (convertController.text.isNotEmpty && converterCursor > 0) {
                convertController.text =
                    convertController.text.substring(0, converterCursor - 1) +
                        convertController.text.substring(converterCursor);
                freezeCursor(convertController, converterCursor);
              }
            } else {
              // Direct insertion without Indian comma injection to prevent hexadecimal corruption
              final int cur = converterCursor.clamp(0, convertController.text.length);
              final String text = convertController.text;
              convertController.text = '${text.substring(0, cur)}$hex${text.substring(cur)}';
              convertController.selection = TextSelection.collapsed(offset: cur + hex.length);
            }
            convert(setttState);
          });
        },
        child: (hex == "DE")
            ? Icon(
                Icons.backspace_rounded,
                color: isDark ? bTheme.shade200 : bTheme.shade800,
                size: 20,
              )
            : Text(
                hex,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: (hex == 'AC')
                      ? (isDark ? bTheme.shade200 : bTheme.shade800)
                      : (isDark ? Colors.grey.shade100 : Colors.grey.shade900),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget convertedListItem(String numberSystem, BuildContext context) {
    String displayValue;
    String badge;
    if (numberSystem == "Decimal") {
      displayValue = decimalValue;
      badge = "DEC :";
    } else if (numberSystem == "Hexadecimal") {
      displayValue = hexValue;
      badge = "HEX :";
    } else if (numberSystem == "Binary") {
      displayValue = binaryValue;
      badge = "BIN :";
    } else {
      displayValue = octalValue;
      badge = "OCT :";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.90),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bTheme.shade300.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: GoogleFonts.ubuntuMono(
                  fontSize: 15,
                  color: bTheme.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  (displayValue.isEmpty || displayValue == '-') ? '0' : displayValue,
                  style: GoogleFonts.ubuntuMono(
                    fontSize: 18,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                size: 19,
                color: bTheme.shade300,
              ),
              tooltip: "Copy $badge",
              onPressed: () async {
                final String valToCopy = (displayValue.isEmpty || displayValue == '-') ? '0' : displayValue;
                if (valToCopy != 'Invalid') {
                  await Clipboard.setData(
                    ClipboardData(text: valToCopy.replaceAll(',', '')),
                  );
                  toastMsg('$badge copied');
                } else {
                  toastMsg('Nothing to copy');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void scrollTheExpression([String? _]) {
    if (!scrollController.hasClients) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      final text = controller.text;
      if (text.isEmpty) {
        if (scrollController.offset != 0.0) {
          scrollController.jumpTo(0.0);
        }
        return;
      }

      final double maxScroll = scrollController.position.maxScrollExtent;
      if (maxScroll <= 0.0) return;

      final int cur = controller.selection.baseOffset.clamp(0, text.length);
      // When cursor is at the end (typing normally at bottom right), keep scrolled to the bottom
      if (cur >= text.length) {
        scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else if (cur == 0) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String getMonthName(int month) {
    const List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  String getFormattedTime(int hour, int minute) {
    final String marker = (hour < 12) ? 'am' : 'pm';
    int displayHour = hour;
    if (displayHour == 0) {
      displayHour = 12;
    } else if (displayHour > 12) {
      displayHour -= 12;
    }
    final String formattedHour = displayHour.toString().padLeft(2, '0');
    final String formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute$marker';
  }
}

// ========================================================
// Smooth Morphing Button (Round -> Squircle on touch)
// ========================================================

class MorphingCalculatorButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color backgroundColor;
  final Color foregroundColor;
  final double width;
  final double height;
  final double elevation;
  final BorderSide borderSide;

  const MorphingCalculatorButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.width,
    required this.height,
    this.elevation = 2,
    this.borderSide = BorderSide.none,
  }) : super(key: key);

  @override
  State<MorphingCalculatorButton> createState() =>
      _MorphingCalculatorButtonState();
}

class _MorphingCalculatorButtonState
    extends State<MorphingCalculatorButton> {
  bool _isPressed = false;
  DateTime? _pointerDownTime;
  Timer? _releaseTimer;

  void _handlePointerDown() {
    _releaseTimer?.cancel();
    _pointerDownTime = DateTime.now();
    HapticFeedback.lightImpact();
    if (!_isPressed) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handlePointerUp() {
    final downTime = _pointerDownTime;
    const minHoldDuration = Duration(milliseconds: 200);

    if (downTime != null) {
      final elapsed = DateTime.now().difference(downTime);
      if (elapsed < minHoldDuration) {
        _releaseTimer?.cancel();
        _releaseTimer = Timer(minHoldDuration - elapsed, () {
          if (mounted) {
            setState(() {
              _isPressed = false;
            });
          }
        });
        return;
      }
    }

    _releaseTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handlePointerDown(),
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _handlePointerUp(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onPressed?.call();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: _isPressed ? 180 : 320),
          curve: _isPressed ? Curves.easeOutCubic : Curves.easeInOutCubic,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(_isPressed ? 18 : 300),
            border: Border.fromBorderSide(widget.borderSide),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.35 : 0.18),
                blurRadius: _isPressed ? 3 : widget.elevation * 2,
                offset: Offset(0, _isPressed ? 1 : widget.elevation),
              ),
            ],
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
