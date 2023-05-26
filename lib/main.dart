import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x75DBC9)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SoHa Replenishments'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _controllerPeople;
  String result = '';
  String? _message, body;
  bool quickSend = false;
  List<String> people = [];

  final TextEditingController controller = TextEditingController();
  String initialCountry = 'DK';
  PhoneNumber _number = PhoneNumber(isoCode: 'DK');

  @override
  void initState() {
    super.initState();
    _loadNumber();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    _controllerPeople = TextEditingController();
  }

  void _loadNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      people.add(prefs.getString('phoneNumber') ?? '');
    });
  }

  void _saveNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('phoneNumber', number);
    });
  }

  void _removeNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.remove('phoneNumber');
    });
  }

  Future<void> _sendSMS(List<String> recipients) async {
    try {
      String _result = await sendSMS(
          message: result, recipients: recipients, sendDirect: true);
      setState(() => _message = _result);
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;

    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#aaaaaa', 'Cancel', true, ScanMode.BARCODE);
      // print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      result = barcodeScanRes;
      _message = result;
    });

    if (quickSend && people.isNotEmpty) {
      _send();
    }
  }

  Widget _phoneTile(String name) {
    return Container(
        padding: const EdgeInsets.all(5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text("Phone Number: ", style: TextStyle(fontSize: 16)),
              Text(
                name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  people.remove(name);
                  _removeNumber();
                }),
              ),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: () {
                    _send();
                  },
                  child: const Icon(Icons.send),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () => scanBarcodeNormal(),
                  child: const Icon(Icons.barcode_reader),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
          ),
          body: Builder(builder: (BuildContext context) {
            return Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.all(10),
                child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      if (people.isEmpty || people[0] == '')
                        const SizedBox(height: 0)
                      else
                        SizedBox(
                          height: 70,
                          child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _phoneTile(people[0])),
                        ),
                      if (people.isEmpty || people[0] == '')
                        const SizedBox(height: 20),
                      if (people.isEmpty || people[0] == '')
                        Column(
                          children: [
                            InternationalPhoneNumberInput(
                              onInputChanged: (PhoneNumber number) {
                                setState(() {
                                  _number = number;
                                });
                              },
                              inputBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              selectorConfig: const SelectorConfig(
                                selectorType:
                                    PhoneInputSelectorType.BOTTOM_SHEET,
                              ),
                              ignoreBlank: false,
                              autoValidateMode: AutovalidateMode.disabled,
                              selectorTextStyle:
                                  const TextStyle(color: Colors.black),
                              initialValue: PhoneNumber(isoCode: 'DK'),
                              textFieldController: _controllerPeople,
                              formatInput: true,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                                style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                        const EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 25))),
                                label: const Text('Add Number'),
                                icon: const Icon(Icons.add),
                                onPressed: _controllerPeople.text.isEmpty
                                    ? null
                                    : () => setState(() {
                                          if (people.isNotEmpty) {
                                            people[0] =
                                                "${_number.dialCode!} ${_controllerPeople.text}";
                                            _saveNumber(
                                                "${_number.dialCode!} ${_controllerPeople.text}");
                                            _controllerPeople.clear();
                                          } else {
                                            people.add(
                                                "${_number.dialCode!} ${_controllerPeople.text}");
                                            _saveNumber(
                                                "${_number.dialCode!} ${_controllerPeople.text}");
                                            _controllerPeople.clear();
                                          }
                                        }))
                          ],
                        ),
                      if (people.isEmpty || people[0] == '')
                        const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: quickSend,
                            onChanged: (bool? value) {
                              setState(() {
                                quickSend = value!;
                              });
                            },
                          ),
                          const Text('Quick Send')
                        ],
                      ),
                      if (result == '')
                        const SizedBox(height: 0)
                      else
                        Text('Scan result : $result\n',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                    ]));
          })),
    );
  }

  void _send() {
    if (people.isEmpty) {
      setState(() => _message = 'At Least 1 Person or Message Required');
    } else {
      _sendSMS(people);
    }
  }
}
