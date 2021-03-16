import 'dart:async';
import 'dart:io'; //ใช้สำหรับ import พวก Directory
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:microphone/microphone.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast.dart';
import 'package:trackingsystem/main.dart';
import 'package:trackingsystem/model/voice_model.dart';
import 'package:trackingsystem/utillty/normal_dialog.dart';
import 'package:trackingsystem/views/recorder_home_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import flutter อัดเสียง
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
// import 'list.dart';
// import 'view.dart';

enum AudioState { recording }
AudioState audioState;

class RecordingScreen extends StatefulWidget {
  // final IconData ico;
  // final VoidCallback onPressed;

  // const RecordingScreen({Key key, this.ico, this.onPressed}) : super(key: key);
  // String _appTitle; //อัดเสียง
  // RecordingScreen({Key key, @required String title})
  //     : assert(title != null),
  //       _appTitle = title,
  //       super(key: key);
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  Function save;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  bool stop = false;
  Recording _current;
  FlutterAudioRecorder audioRecorder; // recorder property
  Directory appDir;
  String Voicename, Voicedate;
  List<String> _voiceModels;
  Future<String> _createAlertDialog(BuildContext context) async {
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return ButtonBarTheme(
              data: ButtonBarThemeData(alignment: MainAxisAlignment.center),
              child: AlertDialog(
                titleTextStyle: TextStyle(color: Colors.indigo[700]),
                title: Text("ตั้งชื่อ"),
                content: TextFormField(
                  onChanged: (value) => Voicename = value.trim(),
                  decoration:
                      new InputDecoration(labelText: "ชื่อเสียงที่บันทึก"),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        child: RaisedButton(
                          color: Colors.blue,
                          //elevation: 5.0,
                          child: Text('บันทึก'),

                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onPressed: () {
                            print('Voicename = $Voicename');
                            if (Voicename == null || Voicename.isEmpty) {
                              normalDialog(context,
                                  'กรุณากรอกชื่อเสียงที่จะบันทึกด้วยครับ');
                              print('Have Space');
                            } else {
                              checkVoicename();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ));
        });
  }

  Future<Null> _registerVoiceThread() async {
    String url =
        'http://192.168.1.3:8080/ProjectFlutter/addRecordname.php?isAdd=true&Voicename=$Voicename&Voicedate=$Voicedate';
    try {
      Response response = await Dio().get(url);
      print('res = $response');

      if (response.toString() == 'true') {
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        print("fwr");
      }
    } catch (e) {}
  }

  Future<Null> checkVoicename() async {
    String url =
        'http://192.168.1.3:8080/ProjectFlutter/getVoicenamewhereVoicename.php?isAdd=true&Voicename=$Voicename';
    try {
      Response response = await Dio().get(url);
      if (response.toString() == 'null') {
        _registerVoiceThread();
      } else {
        normalDialog(context,
            'Voicename ชื่อ $Voicename มีการบันทึกชื่อเสียงอันนี้แล้ว กรุณากรอกชื่อเสียงใหม่ด้วยครับ');
      }
    } catch (e) {}
  }

  // จำเป็น
  String _buttonText = 'เรียบร้อย';
  String _stopwatchText = '00:00';
  final _stopWatch = new Stopwatch();
  final _timeout = const Duration(seconds: 1);
  // จำเป็น
  void _startTimeout() {
    new Timer(_timeout, _handleTimeout);
  }

  // จำเป็น
  void _handleTimeout() {
    if (_stopWatch.isRunning) {
      _startTimeout();
    }
    setState(() {
      _setStopwatchText();
    });
  }

  // จำเป็น
  void _startButtonPressedMicrophone() {
    handleAudioColour();

    setState(() {
      _stopWatch.start();
      _startTimeout();
    });
  }

  //จำเป็น
  void _stopButtonPressedMicrophone() {
    setState(() {
      if (_stopWatch.isRunning) {
        _stopWatch.stop();
      }
    });
  }

  //จำเป็น
  void _resetButtonPressed() {
    if (_stopWatch.isRunning) {
      _stopButtonPressedMicrophone(); //ไม่ให้มีการนับเวลาต่อ
    }
    setState(() {
      _stopWatch.reset(); //หยุดเวลาเริ่มเป็น 00:00
    });
  }

  //จำเป็น
  void _setStopwatchText() {
    _stopwatchText = _stopWatch.elapsed.inMinutes.toString().padLeft(2, '0') +
        ':' +
        (_stopWatch.elapsed.inSeconds % 60).toString().padLeft(2, '0');
  }

  @override
  void initState() {
    super.initState();
    FlutterAudioRecorder.hasPermissions.then((hasPermision) {
      if (hasPermision) {
        _currentStatus = RecordingStatus.Initialized;
      }
    });
    _voiceModels = [];
    getExternalStorageDirectory().then((value) {
      appDir = value.parent; //เส้นทางการเก็บ path
      Directory appDirec = Directory("${appDir.path}/Audiorecords/");
      appDir = appDirec;
      appDir.list().listen((onData) {
        _voiceModels.add(onData.path);
      }).onDone(() {
        _voiceModels = _voiceModels.reversed.toList();
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    appDir = null;
    _currentStatus = RecordingStatus.Unset;
    audioRecorder = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   theme: ThemeData(
    //     primarySwatch: Colors.blue,
    //     buttonColor: Colors.blue,
    //   ),
    return Scaffold(
      resizeToAvoidBottomPadding:
          false, //ใช้ในการหลีกเลี่ยง bottom overflow ... pixels
      appBar: AppBar(
        //backgroundColor: Colors.blue,
        title: new Center(
            child: new Text('อัดเสียง', textAlign: TextAlign.center)),
      ),

      //backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            stop == false
                ? AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: handleAudioColour(),
                    ),
                    child: RawMaterialButton(
                      fillColor: Colors.grey[50],
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(30),
                      onPressed: () async {
                        await _onRecordButtonPressed();
                        _startButtonPressedMicrophone();

                        //_onFinish();
                        setState(() {});
                      },
                      child: getIcon(audioState),
                    ),
                  )
                //SizedBox(width: 20),
                : Expanded(
                    child: FittedBox(
                      fit: BoxFit.none,
                      child: Text(
                        _stopwatchText,
                        style: TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
            //recordButton(),
            RaisedButton(
              onPressed: () async {
                _currentStatus != RecordingStatus.Unset ? _stop : null;
                // await _onRecordButtonPressed();
                _stopButtonPressedMicrophone(); //fun1
                _createAlertDialog(context);
              },
              child: Text(_buttonText),
              color: Colors.blue,
              textColor: Colors.white,
              //onPressed: _startStopButtonPressed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            RaisedButton(
              color: Colors.blue,
              textColor: Colors.white,
              child: Text('Reset'),
              onPressed: () {
                _resetButtonPressed(); //fun1
                //Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
    //);
  }

  //จำเป็น
  Color handleAudioColour() {
    return Colors.grey[400];
  }

  //จำเป็น
  Icon getIcon(AudioState state) {
    return Icon(Icons.mic, color: Colors.black, size: 100);
  }

  _initial() async {
    Directory appDir = await getExternalStorageDirectory();
    String jrecord = 'Audiorecords';
    String dato = "${DateTime.now()?.millisecondsSinceEpoch?.toString()}.wav";
    Directory appDirec =
        Directory("${appDir.parent.parent.parent.parent.path}/$jrecord/");
    if (await appDirec.exists()) {
      String patho = "${appDirec.path}$dato";
      audioRecorder = FlutterAudioRecorder(patho, audioFormat: AudioFormat.WAV);
      await audioRecorder.initialized;
    } else {
      appDirec.create(recursive: true);
      String patho = "${appDirec.path}$dato";
      audioRecorder = FlutterAudioRecorder(patho, audioFormat: AudioFormat.WAV);
      await audioRecorder.initialized;
    }
  }

  Future<void> _onRecordButtonPressed() async {
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          _recordo();
          break;
        }
      case RecordingStatus.Recording:
        {
          _pause();
          break;
        }
      case RecordingStatus.Paused:
        {
          _resume();
          break;
        }
      case RecordingStatus.Stopped:
        {
          _stop();
          break;
        }
      default:
        break;
    }
  }

  _start() async {
    await audioRecorder.start();
    var recording = await audioRecorder.current(channel: 0);
    setState(() {
      _current = recording;
    });
    const tick = const Duration(microseconds: 50);
    new Timer.periodic(tick, (Timer t) async {
      if (_currentStatus == RecordingStatus.Stopped) {
        t.cancel();
      }

      var current = await audioRecorder.current(channel: 0);
      // print(current.status);
      setState(() {
        _current = current;
        _currentStatus = _current.status;
      });
    });
  }

  _resume() async {
    await audioRecorder.resume();
  }

  _pause() async {
    await audioRecorder.pause();
  }

  _stop() async {
    var result = await audioRecorder.stop();
    save();
    setState(() {
      _current = result;
      _currentStatus = _current.status;
      _current.duration = null;
      stop = false;
    });
  }

  Future<void> _recordo() async {
    if (await FlutterAudioRecorder.hasPermissions) {
      await _initial();
      await _start();
      setState(() {
        _currentStatus = RecordingStatus.Recording;
        stop = true;
      });
    } else {}
  }

  _onFinish() {
    _voiceModels.clear();
    print(_voiceModels.length.toString());
    appDir.list().listen((onData) {
      _voiceModels.add(onData.path);
    }).onDone(() {
      _voiceModels.sort();
      _voiceModels = _voiceModels.reversed.toList();
      setState(() {});
    });
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'list.dart';
// import 'view.dart';

// class HomePage extends StatefulWidget {
//   final String _appTitle;

//   const HomePage({Key key, @required String title})
//       : assert(title != null),
//         _appTitle = title,
//         super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   Directory appDir;
//   List<String> records;

//   @override
//   void initState() {
//     super.initState();
//     records = [];
//     getExternalStorageDirectory().then((value) {
//       appDir = value.parent.parent.parent.parent;
//       Directory appDirec = Directory("${appDir.path}/Audiorecords/");
//       appDir = appDirec;
//       appDir.list().listen((onData) {
//         records.add(onData.path);
//       }).onDone(() {
//         records = records.reversed.toList();
//         setState(() {});
//       });
//     });
//   }

//   @override
//   void dispose() {
//     appDir = null;
//     records = null;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {},
//         child: InkWell(
//           child: Icon(Icons.mic),
//           onTap: () {
//             show(context);
//           },
//         ),
//       ),
//       appBar: AppBar(
//         title: Text(
//           widget._appTitle,
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Records(
//               records: records,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   _onFinish() {
//     records.clear();
//     print(records.length.toString());
//     appDir.list().listen((onData) {
//       records.add(onData.path);
//     }).onDone(() {
//       records.sort();
//       records = records.reversed.toList();
//       setState(() {});
//     });
//   }

//   void show(BuildContext context) {
//     showModalBottomSheet<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           height: 200,
//           color: Colors.white70,
//           child: Recorder(
//             save: _onFinish,
//           ),
//         );
//       },
//     );
//   }
// }
