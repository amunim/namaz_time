import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:duration_picker/duration_picker.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:namaz_time/timeline.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'duration_picker.dart';

final List<String> titles = [
  "SubhanaK-Allahumma",
  "Surah Fatiha",
  "Any other Surah",
  "Rukoo",
  "Qiyam",
  "Sajdah 1",
  "Peace to the right and left (sitting)",
  "Sajdah 2",
  "Tashahhud Short",
  "Tashahhud Long"
];

final List<String> descriptions = [
  "Estimated time",
  "Estimated time",
  "Estimated time",
  "Estimated time",
  "Estimated time",
  "Estimated time",
  "Juloos",
  "Estimated time",
  "Estimated time",
  "Estimated time"
];
List<String> processesEnglish = [
  "SubhanaK-Allahumma",
  "Fatiha",
  "Surah",
  "Rukoo",
  "Qiyam",
  "Sajdah",
  "sitting",
  "Sajdah",
  "Tashahhud",
  "Tashahhud"
];
List<String> processesArabic = [
  "ثنا",
  "سورہ فاتحہ",
  "سورہ (قرآت)",
  "رکوع",
  "قیام",
  "سجدہ",
  "درمیان سجدہ",
  "سجدہ",
  "مختصر تشھد",
  "طویل تشھد"
];

SharedPreferences? prefs;

enum Languages { english, arabic }

class PrefsUpdate extends ChangeNotifier {
  void onUpdate() {
    notifyListeners();
  }
}

PrefsUpdate updates = PrefsUpdate();

Languages language = Languages.arabic;

Map<int, TextEditingController> controllers = {};
Map<int, int> savedTime = {};

final _formKey = GlobalKey<FormState>();

bool _started = false;
int totalRaka = 0;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namaz Time',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void refresh() => setState(() {});

  Future _getPrefs() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
      if (prefs!.containsKey("0")) {
        for (var i = 0; i < titles.length; i++) {
          savedTime[i] = prefs!.getInt(i.toString())!;
        }
      }
      if (prefs!.containsKey("language")) {
        language = EnumToString.fromString(
            Languages.values, prefs!.getString("language")!)!;
      }
      updates.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (prefs == null) {
      _getPrefs();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Namaz Time"),
        actions: [
          !_started
              ? IconButton(
                  onPressed: () {
                    _getPrefs();
                    _showConfigPage(context);
                  },
                  icon: const Icon(Icons.settings))
              : IconButton(
                  onPressed: () => setState(() {
                        _started = false;
                      }),
                  icon: const Icon(Icons.cancel_outlined))
        ],
      ),
      body: Center(
        child: !_started
            ? StartControls(
                notifyParent: refresh,
              )
            : StartPray(
                onEnd: refresh,
                now: DateTime.now(),
              ),
      ),
      floatingActionButton: _started
          ? FloatingActionButton(
              onPressed: () => setState(
                () {
                  _started = false;
                },
              ),
              child: const Icon(Icons.cancel_outlined),
            )
          : null,
    );
  }

  void _showConfigPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Settings(
              onSave: refresh,
            )));
  }
}

class StartControls extends StatefulWidget {
  const StartControls({Key? key, required this.notifyParent}) : super(key: key);
  final Function() notifyParent;

  @override
  State<StartControls> createState() => _StartControlsState();
}

class _StartControlsState extends State<StartControls> {
  _StartControlsState() {
    updates.addListener(() => setState(() {}));
  }

  void click() => setState(() {
        _started = true;
        widget.notifyParent();
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OutlinedButton(
            onPressed: savedTime.length > 1
                ? () {
                    totalRaka = 2;
                    click();
                  }
                : null,
            child: const Text("2 Rakat")),
        const SizedBox(height: 20),
        OutlinedButton(
            onPressed: savedTime.length > 1
                ? () {
                    totalRaka = 3;
                    click();
                  }
                : null,
            child: const Text("3 Rakat")),
        const SizedBox(height: 20),
        OutlinedButton(
            onPressed: savedTime.length > 1
                ? () {
                    totalRaka = 4;
                    click();
                  }
                : null,
            child: const Text("4 Rakat"))
      ],
    );
  }
}

class StartPray extends StatefulWidget {
  const StartPray({Key? key, required this.onEnd, required this.now})
      : super(key: key);
  final Function onEnd;
  final DateTime now;

  @override
  State<StartPray> createState() => _StartPray();
}

class _StartPray extends State<StartPray> {
  int i = 0;
  int currentRaka = 1;
  late CountdownController countdownController;
  late TimelineController timelineController;

  @override
  void initState() {
    super.initState();
    countdownController = CountdownController(
        duration: Duration(seconds: prefs!.getInt(i.toString())!),
        onEnd: start);

    timelineController = TimelineController();
    if (language != Languages.english) {
      timelineController.setProcessList(processesArabic);
    }
    countdownController.start();
  }

  void start() {
    if (i <= 7) {
      setState(() {
        i = i + 1;
        countdownController.value =
            Duration(seconds: prefs!.getInt(i.toString())!).inMilliseconds;
        timelineController.updateProcess(i);
        countdownController.start();
      });
      return;
    }

    if (i == 9) {
      setState(() {
        _started = false;
        i = 1;
        currentRaka = 1;
        dispose();
        widget.onEnd();
      });
      return;
    }

    // if (i == 8) {
    //   setState(() {
    //     _started = false;
    //     i = 1;
    //     currentRaka = 1;
    //     dispose();
    //     widget.onEnd();
    //   });
    //   return;
    // }

    if (currentRaka == 1) {
      i = 1;
      currentRaka = currentRaka + 1;
    } else if (currentRaka == 2) {
      if (totalRaka == 2) {
        i = 9;
      } else {
        i = 1;
      }
    } else if (currentRaka == 3) {
      if (totalRaka == 3) {
        i = 9;
      } else {
        i = 1;
      }
    } else if (currentRaka == 4) {
      i = 9;
    }

    setState(() {
      countdownController.value =
          Duration(seconds: prefs!.getInt(i.toString())!).inMilliseconds;
      timelineController.updateProcess(i);
      countdownController.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Align(
        alignment: const FractionalOffset(0.5, 0.2),
        child: Text(
          'Start Time ${widget.now.hour}:${widget.now.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 50),
        ),
      ),
      Countdown(
          countdownController: countdownController,
          builder: (BuildContext context, Duration time) {
            return Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    language == Languages.english
                        ? 'Rakah: $currentRaka'
                        : 'ركعة: $currentRaka',
                    style: const TextStyle(fontSize: 30),
                  ),
                  Text(
                    language == Languages.english
                        ? titles[i]
                        : processesArabic[i],
                    style: const TextStyle(fontSize: 30),
                  ),
                  Text(time.inSeconds.toString(),
                      style: const TextStyle(fontSize: 60)),
                ],
              ),
            );
          }),
      Align(
        alignment: FractionalOffset.bottomCenter,
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ProcessTimelinePage(controller: timelineController))),
      )
    ]);
  }

  @override
  void dispose() {
    // countdownController.dispose();
    super.dispose();
  }
}

class Settings extends StatefulWidget {
  const Settings({Key? key, required this.onSave}) : super(key: key);
  final Function onSave;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final List<TimeInput> settingsPage = [];
  _SettingsState() {
    _buildAllSettings();
  }

  void _buildAllSettings() {
    for (var i = 0; i < titles.length; i++) {
      var controller = controllers.putIfAbsent(
          i,
          () => TextEditingController(
              text: prefs!.getInt(i.toString()) == null
                  ? ""
                  : prefs!.getInt(i.toString()).toString()));
      settingsPage.add(TimeInput(
          title: language == Languages.english ? titles[i] : processesArabic[i],
          name: descriptions[i],
          controller: controller));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          itemCount: (settingsPage.length * 2) + 2,
          itemBuilder: (context, index) {
            if (index == (settingsPage.length * 2) + 1) {
              return SubmitButton(
                savedNotification: widget.onSave,
              );
            } else if (index == (settingsPage.length * 2)) {
              return Column(
                children: [
                  const Text("Select a language",
                      style: TextStyle(fontSize: 20)),
                  DropdownButton<Languages>(
                      value: language,
                      items: Languages.values.map((e) {
                        return DropdownMenuItem(
                            child: Text(e.toString()), value: e);
                      }).toList(),
                      onChanged: (Languages? mylanguage) {
                        if (mylanguage != null) {
                          setState(() {
                            language = mylanguage;
                          });
                        }
                      }),
                ],
              );
            } else {
              if (index.isOdd) return const Divider();

              int i = index ~/ 2;
              return ListTile(title: settingsPage[i]);
            }
          },
        ),
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({Key? key, required this.savedNotification})
      : super(key: key);
  final Function savedNotification;

  void submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < controllers.length; i++) {
      prefs.setInt(i.toString(), int.parse(controllers[i]!.value.text));
      savedTime[i] = prefs.getInt(i.toString())!;
    }

    prefs.setString("language", language.toString());

    Navigator.of(context).pop();
    savedNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            return ElevatedButton(
                onPressed: () => submit(context), child: const Text("Save!"));
          })
        ],
      ),
    );
  }
}

class TimeInput extends StatefulWidget {
  const TimeInput(
      {Key? key,
      required this.name,
      required this.title,
      required this.controller,
      this.duration = const Duration(hours: 0, minutes: 0, seconds: 0)})
      : super(key: key);
  final String name;
  final String title;
  final Duration duration;
  final TextEditingController controller;

  @override
  State<TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<TimeInput> {
  late Duration _dialogDuration =
      const Duration(seconds: 0, minutes: 0, hours: 0);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
          ),
          Row(
            children: [
              Text(
                '${widget.name} :',
                style: const TextStyle(fontSize: 15),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: IntrinsicWidth(
                  // width: 200,
                  child: TextFormField(
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please set the time required';
                      }
                      return null;
                    },
                    controller: widget.controller,
                    decoration: InputDecoration(
                        border: _dialogDuration.inSeconds == 0
                            ? const OutlineInputBorder()
                            : const UnderlineInputBorder(),
                        hintText: _dialogDuration.inSeconds == 0
                            ? "Set Time!"
                            : _dialogDuration.inSeconds.toString()),
                    onTap: () async {
                      // Duration result = await showDialog(
                      //     context: context,
                      //     builder: (context) {
                      //       return Dialog(
                      //         shape: RoundedRectangleBorder(
                      //             borderRadius: BorderRadius.circular(40)),
                      //         elevation: 16,
                      //         child: ListView(
                      //           shrinkWrap: true, //just set this property
                      //           padding: const EdgeInsets.all(8.0),
                      //           children: [
                      //             Center(
                      //               child: Expanded(
                      //                 child: DurationPicker(
                      //                   baseUnit: BaseUnit.second,
                      //                   duration: _dialogDuration,
                      //                   onChange: (value) => setState(
                      //                       () => _dialogDuration = value),
                      //                 ),
                      //               ),
                      //             ),
                      //             Row(
                      //               mainAxisAlignment: MainAxisAlignment.end,
                      //               children: [
                      //                 TextButton(
                      //                     onPressed: () => setState(() {
                      //                           Navigator.of(context).pop(
                      //                               const Duration(
                      //                                   seconds: 0,
                      //                                   minutes: 0,
                      //                                   hours: 0));
                      //                         }),
                      //                     child: const Text("Cancel")),
                      //                 TextButton(
                      //                     onPressed: () =>
                      //                         //close dialog
                      //                         Navigator.of(context)
                      //                             .pop(_dialogDuration),
                      //                     child: const Text("Save"))
                      //               ],
                      //             )
                      //           ],
                      //         ),
                      //       );
                      //     });
                      var result = await showDurationPicker(
                          context: context,
                          initialTime: _dialogDuration,
                          baseUnit: BaseUnit.second,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.lightBlue[50]!,
                                    spreadRadius: 3)
                              ]));
                      setState(() {
                        if (result != null) {
                          _dialogDuration = result;
                          widget.controller.value = TextEditingValue(
                              text: result.inSeconds.toString());
                        }
                      });
                    },
                  ),
                ),
              ),
              const Text("seconds")
            ],
          )
        ],
      ),
    );
  }
}
