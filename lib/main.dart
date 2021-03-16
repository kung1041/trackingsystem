import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackingsystem/utillty/my_style.dart';
import 'package:trackingsystem/views/recorder_home_view.dart';
import 'package:trackingsystem/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackingsystem/model/voice_model.dart';
import 'package:trackingsystem/model/voice_modelservice.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: MaterialApp(
        title: 'Tracking System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  List<VoiceModel> vvoiceModels;

  MyHomePage({
    Key key,
    this.vvoiceModels,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _totalTime;
  int _currentTime;
  bool _loading;
  DateTime date = DateTime.now();
  int _selected = -1;
  double _percent = 0.0;
  bool isPlay = false; //จำเป็น เอา เปิดเสียง ปิดเสียงได้
  AudioPlayer advancedPlayer = AudioPlayer(); //จำเป็น
  @override
  void initState() {
    // TODO: implement initState

    super.initState();

    _loading = true;
    // readVoiceMenu();
    VoiceModelService.getVoices().then((value) {
      setState(() {
        widget.vvoiceModels = value;
        _loading = false;
      });
    });
  }

  // Future<Null> readVoiceMenu() async {
  //   if (_voiceModels.length != 0) {
  //     _voiceModels.reversed.toList();
  //     _voiceModels.clear();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voices'),
        actions: [
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return RecordingScreen();
                }));
              })
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          MyStyle().showProgress();
          Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (a, b, c) => MyApp(),
                transitionDuration: Duration(seconds: 0),
              ));
          return Future.value(false);
        },
        child: ListView.builder(
            itemCount:
                null == widget.vvoiceModels ? 0 : widget.vvoiceModels.length,
            shrinkWrap: true,
            reverse: false,
            itemBuilder: (context, index) {
              // onExpansionChanged:
              // ((newState) {
              //   if (newState) {
              //     setState(() {
              //       _selected = index;
              //     });
              //   }
              // });

              // if (widget.vvoiceModels[index] == null) {
              //   return Center(
              //     child: CircularProgressIndicator(),
              //   );
              // } else {
              return Padding(
                padding: EdgeInsets.only(top: 1.0, left: 16.0, right: 16.0),
                child: Card(
                  elevation: 8.0,
                  child: SingleChildScrollView(
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(widget.vvoiceModels[index].voicename),
                          (isPlay == false)
                              ? IconButton(
                                  icon: Icon(Icons.play_arrow),
                                  onPressed: () async {
                                    setState(() {
                                      isPlay = true;
                                      _selected = index;
                                    });
                                    await advancedPlayer.play(
                                        widget.vvoiceModels
                                            .elementAt(index)
                                            .audioPlayer,
                                        isLocal: true);

                                    setState(() {});
                                    setState(() {
                                      _percent = 0.0;
                                      _selected = index;
                                    });
                                    advancedPlayer.onPlayerCompletion
                                        .listen((_) {
                                      setState(() {
                                        _percent = 0.0;
                                      });
                                    });
                                    advancedPlayer.onDurationChanged
                                        .listen((duration) {
                                      setState(() {
                                        _totalTime = duration.inMicroseconds;
                                      });
                                    });
                                    advancedPlayer.onAudioPositionChanged
                                        .listen((duration) {
                                      setState(() {
                                        _currentTime = duration.inMicroseconds;
                                        _percent = _currentTime.toDouble() /
                                            _totalTime.toDouble();
                                      });
                                    });
                                  })
                              : IconButton(
                                  icon: Icon(Icons.pause),
                                  onPressed: () {
                                    setState(() {
                                      isPlay = false;
                                      _selected = index;
                                    });
                                    advancedPlayer.pause();
                                  }

                                  //   advancedPlayer.play(
                                  //       widget.records.elementAt(i),
                                  //       isLocal: true);
                                  //   setState(() {});
                                  //   setState(() {
                                  //     _selected = i;
                                  //     _percent = 0.0;
                                  //   });

                                  ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              editVoice(
                                  voiceId: widget.vvoiceModels[index].voiceId,
                                  voicename:
                                      widget.vvoiceModels[index].voicename);
                            },
                          ),
                          IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.blue[900],
                              ),
                              onPressed: () =>
                                  deleteVoice(widget.vvoiceModels[index])),
                          //deleteVoice(_voiceModels[index].voiceId,_voiceModels[index].voicename)), เผื่อใช้นะ
                        ],
                      ),
                      subtitle: Row(
                        children: <Widget>[
                          Text(DateFormat("dd/MM/yyyy").format(date)),
                          //Text(_voiceModels[index].voicedate),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }

  Future<bool> editVoice({String voiceId, String voicename}) {
    TextEditingController textEditingController =
        TextEditingController(text: voicename);

    void updateData() {
      var url =
          "http://192.168.1.3:8080/ProjectFlutter/editvoiceWhereId.php?isAdd=true&Voice_id=$voiceId&&Voicename=$voicename";
      http.post(url, body: {
        "voiceId": voiceId,
        "voicename": textEditingController.text,
      });
    }

    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: Column(
          children: [
            TextFormField(
              controller: textEditingController,
              onChanged: (String value) {
                setState(() {
                  voicename = value;
                });
              },
              onFieldSubmitted: (v) {
                updateData();
              },
              decoration: InputDecoration(labelText: 'แก้ไขชื่อเสียง'),
            ),
            Container(
              width: 300.0,
              margin: EdgeInsets.only(top: 10.0),
              child: RaisedButton(
                color: Colors.blue,
                child: Text(
                  'Update Data',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  updateData();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Null> deleteVoice(VoiceModel voicemodel) async {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: MyStyle()
            .showTitleH2('คุณต้องการลบเสียง ${voicemodel.voicename} หรือไม่?'),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                onPressed: () async {
                  Navigator.pop(context);
                  String url =
                      'http://192.168.1.3:8080/ProjectFlutter/deletevoiceWhereId.php?isAdd=true&Voice_id=${voicemodel.voiceId}';
                  await Dio().get(url);
                },
                child: Text('ยืนยันการลบ'),
              ),
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'))
            ],
          )
        ],
      ),
    );
  }
}

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.pink,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: HomePage(
//         title: 'Recordings',
//       ),
//     );
//   }
// }
