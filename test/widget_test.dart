import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calculator/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final String asset = String.fromCharCodes(message!.buffer.asUint8List());
      if (asset == 'AssetManifest.json') {
        return ByteData.view(Uint8List.fromList('{}'.codeUnits).buffer);
      }
      return null;
    });
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Calculator app smoke test and UI rendering without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('AC'), findsOneWidget);
    expect(find.text('()'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('Calculation flow test: 7 + 5 = 12',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('AC clears the expression', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsWidgets);

    await tester.tap(find.text('AC'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, '');
  });

  testWidgets('Delete D removes last character',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, '98');

    await tester.tap(find.byIcon(Icons.backspace));
    await tester.pumpAndSettle();

    expect(textField.controller?.text, '9');
  });

  testWidgets('Indian comma formatting and backspace functionality',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Type 1,00,000
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, '1,000');

    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    expect(textField.controller?.text, '10,000');

    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    expect(textField.controller?.text, '1,00,000');

    // Backspace: 1,00,000 -> 10,000
    await tester.tap(find.byIcon(Icons.backspace));
    await tester.pumpAndSettle();
    expect(textField.controller?.text, '10,000');

    // Multiply: 10,000 × 50 = 5,00,000
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();

    expect(textField.controller?.text, '10,000×50');

    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('5,00,000'), findsOneWidget);
  });

  testWidgets('Button morphing animation changes container border radius',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final buttonFinder = find.ancestor(
      of: find.text('7'),
      matching: find.byType(AnimatedContainer),
    );
    expect(buttonFinder, findsOneWidget);

    AnimatedContainer container = tester.widget<AnimatedContainer>(buttonFinder);
    BoxDecoration decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(300));

    // Press down
    final gesture = await tester.startGesture(tester.getCenter(find.text('7')));
    await tester.pump(const Duration(milliseconds: 200));

    container = tester.widget<AnimatedContainer>(buttonFinder);
    decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(18));

    // Hold down for 2 seconds - should stay in rounded square
    await tester.pump(const Duration(seconds: 2));
    container = tester.widget<AnimatedContainer>(buttonFinder);
    decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(18));

    // Release
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    container = tester.widget<AnimatedContainer>(buttonFinder);
    decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(300));
  });

  testWidgets('Opening Converter bottom sheet works without crash',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Converter'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('HEX :'), findsOneWidget);
    expect(find.text('BIN :'), findsOneWidget);
    expect(find.text('OCT :'), findsOneWidget);

    // Switch to Binary: verify '0b' prefix widget is visible
    await tester.tap(find.text('Binary'));
    await tester.pumpAndSettle();
    expect(find.text('0b'), findsOneWidget);

    // Switch to Hexadecimal: verify '0x' prefix widget is visible
    await tester.tap(find.text('Hexadecimal'));
    await tester.pumpAndSettle();
    expect(find.text('0x'), findsOneWidget);

    // Find input card container before typing
    final inputCardFinder = find.ancestor(
      of: find.byType(TextField).last,
      matching: find.byType(Container),
    ).first;
    final sizeBeforeTyping = tester.getSize(inputCardFinder);
    expect(sizeBeforeTyping.height, 56.0);

    // Type '7'
    await tester.tap(find.widgetWithText(MorphingCalculatorButton, '7').last);
    await tester.pumpAndSettle();

    // Verify input card height remains exactly 56.0 after typing (no height jumping)
    final sizeAfterTyping = tester.getSize(inputCardFinder);
    expect(sizeAfterTyping.height, 56.0);

    // Suffix cancel button should not exist (AC button is used instead)
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);

    final prefixRect = tester.getRect(find.text('0x'));
    final editableRect = tester.getRect(find.byType(EditableText).last);
    expect((prefixRect.bottom - editableRect.bottom).abs(), lessThan(2.0));
  });

  testWidgets('Opening History bottom sheet works without crash',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('End of History'), findsOneWidget);
  });

  testWidgets('Output color is preview before equal and accent after equal',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Type 9 + 3
    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // Answer text is 12 (preview)
    final previewTextFinder = find.text('12');
    expect(previewTextFinder, findsOneWidget);
    final Text previewWidget = tester.widget<Text>(previewTextFinder);
    expect(previewWidget.style?.color, Colors.white60);
    expect(previewWidget.style?.fontWeight, FontWeight.bold);

    // Tap =
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    // Answer text is now accent colored (shade300 of default theme lightGreen)
    final finalTextFinder = find.text('12');
    final Text finalWidget = tester.widget<Text>(finalTextFinder);
    expect(finalWidget.style?.color, Colors.lightGreen.shade300);
    expect(finalWidget.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('Top right buttons in glass container and expression multiline vertical layout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify top right buttons are inside glass container (BackdropFilter inside AppBar)
    final appBarFinder = find.byType(AppBar);
    expect(
      find.descendant(of: appBarFinder, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );

    // Verify input TextField has maxLines: null for multiline vertical scaling
    final inputTextField = tester.widget<TextField>(find.byType(TextField).first);
    expect(inputTextField.maxLines, isNull);
    expect(inputTextField.textAlign, TextAlign.right);

    // Initial short text font size is large (44.0)
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    final updatedInput = tester.widget<TextField>(find.byType(TextField).first);
    expect(updatedInput.style?.fontSize, 44.0);
  });
}
