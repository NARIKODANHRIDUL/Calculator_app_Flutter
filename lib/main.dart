import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  binding.addPostFrameCallback((_) async {
    BuildContext context = binding.renderViewElement as BuildContext;
    await precacheImage(const AssetImage("images/neriquest.png"), context);
    Text("", style: GoogleFonts.ubuntuMono());
    Text("", style: GoogleFonts.nunito());
    binding.allowFirstFrame();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.grey),
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late TextEditingController controller;
  late ScrollController scrollController = ScrollController();

  // String controller.text= '';
  String answer = '';
  int openBracket = 0;
  int closingBracket = 0;
  String strBfrCursor = '';
  int cursor = 0;
/////////////////
  Color bgColor = Color.fromARGB(255, 240, 240, 240);
  Color topBox = Color.fromARGB(255, 207, 207, 207);
  var resultColor = Colors.grey.shade300.withOpacity(0.8);
  var eqColor = Colors.grey.shade100;
  var buttonColor = Color.fromARGB(255, 32, 32, 32);
  bool isDark = true;
  int themeColorId = 1;
  List<List<String>> history = [];
  List<String> inputAnswer = [];
  //////////////////
  double resultSize = 40;
  double eqSize = 50;
  int isEqual = 0;
  String dummyInput = '';

  var bTheme = Colors.lightGreen;

  @override
  void initState() {
    super.initState();
    read();
    controller = TextEditingController();
    // save();//will be better than continuos save()
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  save() async {
    print("Saving...");
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
    prefs.setInt('themeColorId', themeColorId);
    // prefs.setStringList('history', history);
    storeList(history);
  }

  read() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool('isDark') ?? true;
      themeColorId = prefs.getInt('themeColorId') ?? 1;
      retrieveList();
    });
    // print('read: $derk');
  }

  Future<void> storeList(List<List<String>> myList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Store the list in shared preferences as a set of strings
    List<String> stringList =
        myList.map((e) => "${e[0]},${e[1]},${e[2]}").toList();
    await prefs.setStringList('myListKey', stringList);
  }

  Future<List<List<String>>> retrieveList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Retrieve the list from shared preferences and convert it back to the original format
    List<String> stringList = prefs.getStringList('myListKey') ?? [];
    List<List<String>> myList = stringList.map((e) => e.split(",")).toList();
    history = myList;
    return myList;
  }

  @override
  Widget build(BuildContext context) {
    // final hei = MediaQuery.of(context).size.height; //screen height
    final wid = MediaQuery.of(context).size.width; //screen width
    const divider = Divider(height: 10, thickness: 0);
    var verticalDivider = VerticalDivider(width: (1 - 0.22 * 4) / 5 * wid);
    var verticalDivider2 = VerticalDivider(width: (1 - 0.22 * 4) / 10 * wid);

    try {
      calculate(false);
    } catch (e) {}
    save();
    if (isDark) {
      bgColor = Color.fromARGB(255, 23, 23, 23);
      topBox = Color.fromARGB(255, 40, 40, 40);
      resultColor = Colors.grey.shade200.withOpacity(0.8);
      eqColor = Colors.grey.shade100;
      buttonColor = Color.fromARGB(255, 32, 32, 32);
    } else {
      bgColor = Color.fromARGB(255, 232, 232, 232);
      topBox = Color.fromARGB(255, 220, 220, 220);
      resultColor = Colors.grey.shade700.withOpacity(0.8);
      eqColor = Colors.grey.shade800;
      buttonColor = Color.fromARGB(255, 223, 223, 223);
    }

    if (themeColorId == 1)
      bTheme = Colors.lightGreen;
    else if (themeColorId == 2)
      bTheme = Colors.lightBlue;
    else if (themeColorId == 3)
      bTheme = Colors.red;
    else
      bTheme = Colors.orange;

    return Scaffold(
      //bottom button box
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBox,
        elevation: 0,
        title: Text("",
            style: GoogleFonts.openSans(
                fontSize: 25,
                color: bTheme.shade300,
                fontWeight: FontWeight.bold)),
        // toolbarHeight: 60,
        actions: [
          IconButton(
              padding: EdgeInsets.all(0),
              onPressed: () {
                // for resetting for (answer to input)
                isEqual = 0;
                showHistory(context);
              },
              tooltip: "History",
              splashRadius: 28,
              icon: Icon(
                Icons.history,
                size: 35,
                color: bTheme.shade300,
              )),
          PopupMenuButton(
            splashRadius: 28,
            icon:
                Icon(Icons.more_vert_rounded, color: bTheme.shade300, size: 30),
            position: PopupMenuPosition.under,
            color: isDark ? bTheme.shade200 : bTheme.shade300,
            elevation: 5,
            padding: EdgeInsets.all(10),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0))),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 0,
                textStyle: GoogleFonts.nunito(
                    fontSize: 22,
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    fontWeight: FontWeight.w700),
                child: const Text("Theme"),
              ),
              PopupMenuItem(
                value: 1,
                textStyle: GoogleFonts.nunito(
                    fontSize: 22,
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    fontWeight: FontWeight.w700),
                child: const Text("About Us"),
              ),
              PopupMenuItem(
                value: 2,
                textStyle: GoogleFonts.nunito(
                    fontSize: 22,
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    fontWeight: FontWeight.w700),
                child: const Text("Share App"),
              ),
              PopupMenuItem(
                value: 3,
                textStyle: GoogleFonts.nunito(
                    fontSize: 22,
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    fontWeight: FontWeight.w700),
                child: const Text("Rate Us"),
              ),
              PopupMenuItem(
                  value: 4,
                  child: Transform.scale(
                    scale: 1.2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 135,
                        padding: EdgeInsets.all(0),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              bTheme.shade300.withOpacity(0.4),
                              BlendMode.color),
                          child: Image(
                            image: AssetImage("images/neriquest.png"),
                          ),
                        ),
                      ),
                    ),
                  ))
            ],
            onSelected: (value) async {
              if (value == 0) {
                showTheme(wid, context);
              } else if (value == 1)
                openUrl('https://github.com/NARIKODANHRIDUL/');
              else if (value == 2)
                Share.share(
                    "Check out Chess Timer App in Google PlayStore  https://play.google.com/store/apps/details?id=neriquest.chesstimer");
              else if (value == 3)
                openUrl(
                    'https://play.google.com/store/apps/details?id=neriquest.chesstimer');
              else if (value == 4) toastMsg("Created by NeriQuest");
            },
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails details) {
          if (details.velocity.pixelsPerSecond.dy < 0) {
            // for resetting for (answer to input)
            isEqual = 0;
            showHistory(context);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Container(
                  color: topBox,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Scrollbar(
                            thumbVisibility: true,
                            thickness: 1,
                            child: TextField(
                              scrollController: scrollController,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                              autofocus: true,
                              style: GoogleFonts.ubuntuMono(
                                  fontSize: eqSize, color: eqColor),
                              cursorColor: bTheme.shade300,
                              textDirection: TextDirection.ltr,
                              cursorRadius: Radius.circular(12),
                              keyboardType: TextInputType.none,
                              controller: controller,
                              textInputAction: TextInputAction.previous,
                              decoration: InputDecoration.collapsed(
                                hintText: '',
                              ),
                            ),
                          ),
                          Scrollbar(
                            thumbVisibility: true,
                            thickness: 1,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: GestureDetector(
                                onLongPress: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: answer));
                                  toastMsg("$answer copied to Clipboard");
                                },
                                child: Text(
                                  answer,
                                  style: GoogleFonts.ubuntuMono(
                                    color: answer == "Error"
                                        ? Color.fromARGB(255, 252, 114, 63)
                                        : answer == "Infinity" ||
                                                answer == "-Infinity"
                                            ? Color.fromARGB(255, 252, 114, 63)
                                            : answer == "Keep it real"
                                                ? Color.fromARGB(
                                                    255, 252, 114, 63)
                                                : resultColor,
                                    fontSize: resultSize,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  divider,
                  Row(
                    children: [
                      verticalDivider2,
                      extraButton("√", wid),
                      verticalDivider2,
                      extraButton("^", wid),
                      verticalDivider2,
                      extraButton("!", wid),
                      verticalDivider2,
                      extraButton("e", wid),
                      verticalDivider2,
                      extraButton("log", wid),
                      verticalDivider2,
                    ],
                  ),
                  divider,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      mainButton("AC", wid),
                      verticalDivider,
                      mainButton("()", wid),
                      verticalDivider,
                      mainButton("÷", wid),
                      verticalDivider,
                      mainButton('×', wid),
                    ],
                  ),
                  divider,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      mainButton("7", wid),
                      verticalDivider,
                      mainButton("8", wid),
                      verticalDivider,
                      mainButton("9", wid),
                      verticalDivider,
                      mainButton("-", wid),
                    ],
                  ),
                  divider,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      mainButton("4", wid),
                      verticalDivider,
                      mainButton("5", wid),
                      verticalDivider,
                      mainButton("6", wid),
                      verticalDivider,
                      mainButton("+", wid),
                    ],
                  ),
                  divider,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      mainButton("1", wid),
                      verticalDivider,
                      mainButton("2", wid),
                      verticalDivider,
                      mainButton("3", wid),
                      verticalDivider,
                      mainButton("D", wid),
                    ],
                  ),
                  divider,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      mainButton(".", wid),
                      verticalDivider,
                      mainButton("0", wid),
                      verticalDivider,
                      mainButton("=", wid),
                    ],
                  ),
                  divider,
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  ElevatedButton extraButton(String tag, double wid) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          // for resetting for (answer to input)
          isEqual = 0;
          cursor = controller.selection.baseOffset;
          cursor = cursor == -1 ? controller.text.length : cursor;
          strBfrCursor = controller.text.substring(0, cursor);
          ////////////////
          if (tag == '√')
            typeIt('√');
          else if (tag == '^' &&
              strBfrCursor != '' &&
              (isNum(strBfrCursor[strBfrCursor.length - 1]) ||
                  strBfrCursor.endsWith(')') ||
                  strBfrCursor.endsWith('!') ||
                  strBfrCursor.endsWith('e')))
            typeIt('^(');
          else if (tag == '!' &&
              strBfrCursor != '' &&
              (isNum(strBfrCursor[strBfrCursor.length - 1]) ||
                  strBfrCursor.endsWith(')')))
            typeIt('!');
          else if (tag == 'e') if (strBfrCursor.endsWith("√"))
            typeIt('(e');
          else
            typeIt('e');
          else if (tag == 'log') if (strBfrCursor.endsWith("√"))
            typeIt('(㏒(');
          else
            typeIt('㏒(');
          /////////////////
          if (answer != '') {
            eqSize = 50;
            resultSize = 40;
          }
        });

        if (cursor == controller.text.length - 1)
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              var s = scrollController.position.maxScrollExtent;
              print(" Scroll $s");
              scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 100),
                  curve: Curves.easeInOut);
            }
          });
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: tag == '^'
              ? EdgeInsets.only(top: wid * 0.20 / 10)
              : EdgeInsets.all(0),
          child: Text(
            tag,
            style: GoogleFonts.ubuntuMono(
                fontSize: 30, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
          foregroundColor: bTheme.shade300,
          backgroundColor: Colors.transparent,
          fixedSize: Size(wid * 0.18, wid * 0.20 / 2.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(300),
          )),
    );
  }

  ElevatedButton mainButton(String tag, double wid) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            foregroundColor: (isOperator(tag) || tag == '='
                ? isDark
                    ? Colors.grey.shade900
                    : Colors.grey.shade100
                : bTheme.shade300),
            backgroundColor: (isOperator(tag) || tag == '='
                ? isDark
                    ? bTheme.shade300.withOpacity(0.9)
                    : bTheme.shade300.withOpacity(0.7)
                : buttonColor),
            fixedSize: tag == "="
                ? Size(wid * (0.22 * 2 + ((1 - 0.22 * 4) / 5)), wid * 0.22)
                //width = width of 2 small mainButton + gap between them
                : Size(wid * 0.22, wid * 0.22),
            //buttonColor
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(300),
            )),
        onLongPress: () {
          if (tag == 'D') {
            setState(() {
              // for resetting for (answer to input)
              isEqual = 0;
              cursor = controller.selection.baseOffset;
              cursor = cursor == -1 ? controller.text.length : cursor;
              strBfrCursor = controller.text.substring(0, cursor);
              controller.text = controller.text.substring(cursor);
              freezeCursor(1);
            });
          }
        },
        onPressed: () {
          setState(() {
            // for resetting for (answer to input)
            if (tag != '=') isEqual = 0;
            ///////////////////////////
            cursor = controller.selection.baseOffset;
            cursor = cursor == -1 ? controller.text.length : cursor;
            strBfrCursor = controller.text.substring(0, cursor);
            ///////////////////////////

            if (answer != '') {
              eqSize = 50;
              resultSize = 40;
            }

            if (tag == 'AC') {
              controller.text = '';
              answer = '';

              //////////////////////
            } else if (tag == 'D') {
              int value = strBfrCursor.endsWith('㏒(') ? 2 : 1;
              if (controller.text != '') {
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - value) +
                    controller.text.substring(controller.selection.baseOffset);
                freezeCursor(cursor - value + 1);
              }
              //////////////////////
            } else if (tag == '=') {
              if (controller.text != '') {
                isEqual += 1;
                if (isEqual % 2 == 1) {
                  if (isEqual > 2) controller.text = dummyInput;
                  calculate(true);
                  dummyInput = controller.text;
                  eqSize = 40;
                  resultSize = 50;
                  if (answer != '') {
                    if (history.isNotEmpty &&
                        history.last[0] == controller.text)
                      null;
                    else {
                      DateTime now = DateTime.now();
                      String formattedDate =
                          '${now.day} ${getMonthName(now.month)} ${now.year}, ${getFormattedTime(now.hour, now.minute)}';
                      inputAnswer = [controller.text, answer, formattedDate];
                      history.add(inputAnswer);
                      // history.removeAt(2);
                      save();
                    }
                  }
                } else {
                  controller.text = answer;
                  eqSize = 50;
                  resultSize = 40;
                }
                cursor = controller.selection.baseOffset;
                print('cursor >> $cursor');
              } else {
                answer = '';
                toastMsg("Type Some expression and try");
              }

              ////////////////
            } else if (tag == '()') {
              openBracket = strBfrCursor.split("(").length - 1;
              closingBracket = strBfrCursor.split(")").length - 1;

              if (openBracket == closingBracket ||
                  strBfrCursor.endsWith('+') ||
                  strBfrCursor.endsWith("–") ||
                  strBfrCursor.endsWith("×") ||
                  strBfrCursor.endsWith("÷") ||
                  strBfrCursor.endsWith("("))
                typeIt('(');
              else if (openBracket > closingBracket) typeIt(')');

              /////////////////////
            } else if (tag == '-') {
              if (strBfrCursor.endsWith('–'))
                toastMsg(
                    "Invalid Input"); //will not type - if there is already -
              else if (strBfrCursor.endsWith('÷') ||
                  strBfrCursor.endsWith('×') ||
                  strBfrCursor.endsWith('+')) {
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - 1) +
                    controller.text.substring(controller.selection.baseOffset);
                freezeCursor(cursor);
                typeIt('–');
              } else
                typeIt('–');
              ///////////////////////
            } else if (isNum(tag) || tag == '.') {
              if (tag == '.' &&
                  (strBfrCursor.endsWith('(') ||
                      strBfrCursor.endsWith(')') ||
                      strBfrCursor.endsWith('.')))
                toastMsg("Invalid Input");
              else
                typeIt(tag);
              ///////////////////////
            } else {
              if (strBfrCursor != '–' &&
                  !strBfrCursor.endsWith('(–') &&
                  (strBfrCursor.endsWith('÷') ||
                      strBfrCursor.endsWith('×') ||
                      strBfrCursor.endsWith('–') ||
                      strBfrCursor.endsWith('+'))) {
                controller.text = controller.text
                        .substring(0, controller.selection.baseOffset - 1) +
                    controller.text.substring(controller.selection.baseOffset);
                freezeCursor(cursor);
                typeIt(tag);
              } else if ((strBfrCursor != '' &&
                  (isNum(strBfrCursor[strBfrCursor.length - 1]) ||
                      strBfrCursor.endsWith(')') ||
                      strBfrCursor.endsWith('!') ||
                      strBfrCursor.endsWith('e'))))
                typeIt(tag);
              else
                toastMsg("Invalid Input");
            }
          });
          /////////////////////////
          //fixscroll
          scrollTheExpression(strBfrCursor);
        },
        child: Center(
            child: tag == 'D'
                ? Icon(
                    Icons.backspace,
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  )
                : (tag == '×'
                    ? Icon(
                        Icons.close,
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        size: wid * 0.08,
                      )
                    : (tag == '+'
                        ? Icon(
                            Icons.add,
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                            size: wid * 0.08,
                          )
                        : (tag == '-'
                            ? Icon(
                                Icons.horizontal_rule_rounded,
                                color: isDark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade100,
                                size: wid * 0.08,
                              )
                            : FittedBox(
                                child: Padding(
                                  padding: tag == '.'
                                      ? EdgeInsets.only(bottom: wid * 0.22 / 5)
                                      : EdgeInsets.all(0),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.ubuntuMono(
                                        fontSize: tag == '=' ||
                                                tag == '÷' ||
                                                tag == '.'
                                            ? 50
                                            : 40,
                                        fontWeight: tag == '÷'
                                            ? FontWeight.w200
                                            : FontWeight.w500),
                                  ),
                                ),
                              ))))));
  }

  void showTheme(double wid, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 40,
          backgroundColor: topBox,
          shape: const RoundedRectangleBorder(
              side: BorderSide(width: 3, color: Colors.white12),
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "THEME",
                style: GoogleFonts.abel(
                    color: Colors.grey.shade500,
                    fontSize: 40,
                    fontWeight: FontWeight.w900),
              ),
              VerticalDivider(
                width: 15,
              ),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                child: ElevatedButton(
                  onPressed: () {
                    save();
                    setState(() {
                      isDark = !isDark;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Icon(isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(0),
                    fixedSize: Size(70, 70),
                    elevation: 30,
                    backgroundColor: isDark
                        ? Colors.grey.shade700.withOpacity(0.7)
                        : Color.fromARGB(255, 200, 200, 200),
                  ),
                ),
              )
            ],
          )),
          contentPadding: EdgeInsets.all(0),
          titlePadding: EdgeInsets.only(top: 20, bottom: 10),
          insetPadding: EdgeInsets.all(0),
          actionsPadding: EdgeInsets.all(10),
          actions: [
            FittedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      themeButton(wid, "Green", context),
                      VerticalDivider(
                        width: 10,
                      ),
                      themeButton(wid, "Blue", context),
                    ],
                  ),
                  Divider(height: 10),
                  Row(
                    children: [
                      themeButton(wid, "Red", context),
                      VerticalDivider(width: 10),
                      themeButton(wid, "Orange", context),
                      Divider(height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  ClipRRect themeButton(double wid, String color, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      child: Container(
        height: wid * 0.35,
        width: wid * 0.35,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: (color == "Green")
                  ? Colors.lightGreen.shade300
                  : (color == "Blue")
                      ? Colors.lightBlue.shade200
                      : (color == "Red")
                          ? Colors.redAccent.shade100
                          : Colors.orange.shade300),
          child: Text(
            color.toUpperCase(),
            style: GoogleFonts.openSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: (color == "Green")
                    ? Colors.lightGreen.shade600
                    : (color == "Blue")
                        ? Colors.lightBlue.shade600
                        : (color == "Red")
                            ? Colors.redAccent.shade200
                            : Colors.orange.shade600),
          ),
          onPressed: () {
            save();
            setState(() {
              if (color == "Green")
                themeColorId = 1;
              else if (color == "Blue")
                themeColorId = 2;
              else if (color == "Red")
                themeColorId = 3;
              else
                themeColorId = 4;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void calculate(bool pressed) {
    if (controller.text == '') answer = '';
    String userInputToCalculate = controller.text;
    print("-----------------------------\nGiven => $userInputToCalculate");
    ////////////////////////////////
    if (isOperator(userInputToCalculate[userInputToCalculate.length - 1]) ||
        userInputToCalculate.endsWith('√') ||
        userInputToCalculate.endsWith('^')) {
      userInputToCalculate =
          userInputToCalculate.substring(0, userInputToCalculate.length - 1);
    } // if last digit is an operator it will ignore it

    while (userInputToCalculate.contains('√√')) {
      userInputToCalculate = userInputToCalculate.replaceAllMapped(
          RegExp(r'√√([^,]+)'), (match) => "√(√${match[1]})");
    } //when muultiple √√√ comes it gives correct brackets
    if (userInputToCalculate.endsWith('e')) userInputToCalculate += '^1';
    openBracket = userInputToCalculate.split("(").length - 1;
    closingBracket = userInputToCalculate.split(")").length - 1;
    if (openBracket > closingBracket && userInputToCalculate != '(')
      userInputToCalculate =
          userInputToCalculate + ')' * (openBracket - closingBracket);

    ////////////////////////////////
    userInputToCalculate = userInputToCalculate.replaceAll('×', '*');
    userInputToCalculate = userInputToCalculate.replaceAll('÷', '/');
    userInputToCalculate = userInputToCalculate.replaceAll('–', '-');
    userInputToCalculate = userInputToCalculate.replaceAll('㏒', 'log');
    userInputToCalculate = userInputToCalculate.replaceAll('√', '*sqrt');
    userInputToCalculate = userInputToCalculate.replaceAll('(*', '(');
    userInputToCalculate = userInputToCalculate.replaceAll(')(', ')*(');

    //if * at begining delete it (created due to *sqrt)
    ////////////////////////////////
    if (userInputToCalculate.startsWith('*'))
      userInputToCalculate =
          userInputToCalculate.substring(1, userInputToCalculate.length);
    ////////////////////////////////
    // log(5*3) => log(10, 5*3) //log(10,x) is thr syntax
    int logCount = userInputToCalculate.split("log").length - 1;
    for (int i = 0; i < logCount; i++) //when there is multiple log
      userInputToCalculate = userInputToCalculate.replaceAllMapped(
          RegExp(r"log\(([^,]+)\)"), (match) => "log(10, ${match.group(1)})");

    //makes 8e => 8*e
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r"(\d)+e"), (match) => "${match.group(1)}*e");
    // makes 9(5) => 9*(5)
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'(\d+)\('), (match) => '${match.group(1)}*(');
    // makes (5)9 => (5)*9
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'\)(\d+)'), (match) => ')*${match.group(1)}');
    // makes 5!9 => 5!*9
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'\!(\d+)'), (match) => '!*${match.group(1)}');
    // makes 5!(9 => 5!*(9
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'\!(\()'), (match) => '!*${match.group(1)}');
    // makes 5!9 => 5!*9
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'\!(log)'), (match) => '!*${match.group(1)}');
    // e5 => e^1 *5
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'\e(\d+)'), (match) => 'e^1*${match.group(1)}');
    //e( => e^1 *(
    userInputToCalculate = userInputToCalculate.replaceAllMapped(
        RegExp(r'e(\()'), (match) => 'e^1*${match.group(1)}');
    // //sqrtlog => sqrt
    // userInputToCalculate = userInputToCalculate.replaceAllMapped(
    //     RegExp(r'e(\()'), (match) => 'e^1*${match.group(1)}');
    // //e( => e^1 *(
    // userInputToCalculate = userInputToCalculate.replaceAllMapped(
    //     RegExp(r'e(\()'), (match) => 'e^1*${match.group(1)}');

    print("calculate => $userInputToCalculate");
    /////////////////////////////////
    try {
      Parser p = Parser();
      Expression exp = p.parse(userInputToCalculate);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      print("eval $eval");
      setState(() {
        answer = eval.toString();

        // fixing floating point error by rounding last digit
        if (answer.contains('.')) {
          int decimalLength = answer.substring(answer.indexOf('.') + 1).length;
          if (answer.contains('e'))
            decimalLength = answer
                .substring(answer.indexOf('.') + 1, answer.indexOf('e'))
                .length;
          if (decimalLength >= 16) answer = roundDouble(answer);
        }
        print("string answdasdaer = > " + answer);
        answer = removeTrailingZeros(answer);
        if (!answer.contains('e')) answer = toExponentForm(answer);
        answer = removeExtraDecimals(answer);

        if ((pressed == false &&
                !isNum(answer[answer.length - 1]) &&
                eqSize == 50) ||
            (controller.text == answer))
          setState(() {
            answer = '';
          });
        print("answer2:  $answer");
        answer = answer == 'NaN' ? 'Keep it real' : answer;
        //Nan comes when sqrt(-ve)
      });
    } catch (e) {
      print("Error in answer");

      setState(() {
        answer = controller.text == '' ? '' : "Error";
        print(eqSize);
        if (answer == 'Error' && eqSize == 50)
          setState(() {
            answer = '';
          });
      });
    }
  }

  bool isOperator(String value) {
    if (value == 'AC' ||
        value == 'D' ||
        value == '()' ||
        value == '÷' ||
        value == '×' ||
        value == '-' ||
        value == '+') {
      return true;
    } else {
      return false;
    }
  }

  bool isNum(String value) {
    if (value == '1' ||
        value == '2' ||
        value == '3' ||
        value == '4' ||
        value == '5' ||
        value == '6' ||
        value == '7' ||
        value == '8' ||
        value == '9' ||
        value == '0') {
      return true;
    } else {
      return false;
    }
  }

  bool isExtra(String value) {
    if (value == '√' || value == '^' || value == '!' || value == 'e') {
      return true;
    } else {
      return false;
    }
  }

  void typeIt(String str) {
    cursor = controller.selection.baseOffset;
    cursor = cursor == -1 ? controller.text.length : cursor;
    print("cursor = $cursor\n");
    controller.text = controller.text.substring(0, cursor) +
        str +
        controller.text.substring(cursor);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: cursor + str.length));
  }

  void openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void freezeCursor(int cursor) {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: cursor - 1),
    );
  }

  void toastMsg(String h) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: h,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey.shade900,
        textColor: bTheme.shade300,
        fontSize: 19.0);
  }

  void showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.3,
              maxChildSize: 0.8,
              minChildSize: 0.2,
              builder: (context, scrollController) => Container(
                color: bgColor,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        color: bgColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              alignment: Alignment.bottomCenter,
                              height: 80,
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: buttonColor.withAlpha(200),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 7,
                                      offset: Offset(1, 1),
                                      spreadRadius: 1),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 50,
                                  ),
                                  Text('History',
                                      style: GoogleFonts.nunito(
                                          fontSize: 35,
                                          color: bTheme.shade300,
                                          fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: IconButton(
                                        onPressed: () {
                                          deleteHistory(context);
                                        },
                                        icon: Icon(
                                          Icons.delete_forever_rounded,
                                          size: 35,
                                          color: bTheme.shade300,
                                        )),
                                  )
                                ],
                              ),
                            ),
                            Divider(
                              height: 5,
                            ),
                            if (history != [])
                              for (int i = history.length - 1; i >= 0; i--)
                                historyListItem(i),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Container(
                                child: Text(
                                  "End of History",
                                  style: GoogleFonts.ubuntuMono(
                                      fontSize: 20, color: bTheme.shade300),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -1,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: Container(
                padding: EdgeInsets.all(15),
                height: 40,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: buttonColor.withAlpha(200),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 7,
                        offset: Offset(1, 1),
                        spreadRadius: 1),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                color: Colors.white,
                width: 50,
                height: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> deleteHistory(BuildContext context) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      enableDrag: true,
      backgroundColor: buttonColor,
      context: context,
      builder: (context) => Container(
          padding: EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Divider(
                height: 10,
              ),
              Text(
                "Do you want to clear the history or memory  ?",
                style: GoogleFonts.nunito(fontSize: 21, color: bTheme.shade300),
              ),
              Divider(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      history = [];
                    });
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(15),
                      backgroundColor: topBox,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      )),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_rounded,
                        size: 25,
                        color: Colors.grey,
                      ),
                      VerticalDivider(
                        width: 10,
                      ),
                      Text("Delete all history",
                          style: GoogleFonts.nunito(
                              fontSize: 20, color: Colors.grey)),
                    ],
                  ))
            ],
          )),
    );
  }

  Padding historyListItem(int i) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            controller.text = history[i][0];
          });
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              history[i][0],
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              history[i][1],
              style: GoogleFonts.nunito(
                  fontSize: 25,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                history[i][2],
                style: GoogleFonts.nunito(
                  color: Colors.grey.shade600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String roundDouble(String answer) {
    int index15 = answer.indexOf('.') + 15;
    int num16 = int.parse(answer[index15 + 1]);
    double add = (num16 >= 5) ? 10e-16 : 0;
    double a = double.parse(answer.substring(0, index15 + 1)) + add;
    return (a.toString() + answer.substring(index15 + 2));
  }

  String removeTrailingZeros(String value) {
    int eIndex = (value.contains('e')) ? value.indexOf('e') : value.length;
    int dotIndex = value.indexOf('.');
    int i = eIndex - 1;
    while (i >= dotIndex && (value[i] == '0' || value[i] == '.')) i--;
    return value.substring(0, i + 1) + value.substring(eIndex);
  }

  String removeExtraDecimals(String value) {
    int eIndex = value.indexOf('e');
    eIndex = eIndex == -1 ? value.length : eIndex;
    int dotIndex = value.indexOf('.');
    if (dotIndex == -1) return value;
    int i = dotIndex + 9;
    if (i >= eIndex) i = eIndex;
    return value.substring(0, dotIndex + 1) +
        value.substring(dotIndex + 1, i) +
        value.substring(eIndex);
  }

  String toExponentForm(String value) {
    if (value.length > 14) {
      int dot = (value.indexOf('.') != -1) ? value.indexOf('.') : value.length;
      int exp = dot - 1;
      if (dot < 8)
        return value;
      else if (exp > 14)
        return value[0] + '.' + value.substring(1, 14) + "e+$exp";
      else
        return value[0] +
            '.' +
            value.substring(1, dot) +
            value.substring(dot + 1, 14) +
            'e+$exp';
    }
    return value;
  }

  int a = 1;
  void scrollTheExpression(String strBfrCursor) {
    bool b = (controller.text.length >= a) ? true : false;

    if (scrollController.position.maxScrollExtent != 0 && b) {
      a = controller.text.length;
      b = false;
    }
    if (strBfrCursor.length >= a) {}

    if (cursor == controller.text.length - 1)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          var s = scrollController.position.maxScrollExtent;
          print(" Scroll $s");
          scrollController.animateTo(scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
        }
      });
    else {
      // SchedulerBinding.instance.addPostFrameCallback((_) {
      //   scrollController.animateTo(20.272727272727252,
      //       duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
      // });
    }
  }

  String getMonthName(int month) {
    List<String> monthNames = [
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
    return monthNames[month - 1];
  }

  String getFormattedTime(int hour, int minute) {
    String marker = (hour < 12) ? 'am' : 'pm';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    String formattedHour = hour.toString().padLeft(2, '0');
    String formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute$marker';
  }

/////////////////////////
} ///////THE END/////////
///////////////////////
