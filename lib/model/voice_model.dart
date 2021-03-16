// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';

List<VoiceModel> voiceFromJson(String str) =>
    List<VoiceModel>.from(json.decode(str).map((x) => VoiceModel.fromJson(x)));

String voiceToJson(List<VoiceModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VoiceModel {
  VoiceModel({
    this.voiceId,
    this.voicename,
    this.voicedate,
    this.audioPlayer,
  });

  String voiceId;
  String voicename;
  String voicedate;
  String audioPlayer;

  factory VoiceModel.fromJson(Map<String, dynamic> json) => VoiceModel(
        voiceId: json["Voice_id"],
        voicename: json["Voicename"],
        voicedate: json["Voicedate"],
        audioPlayer: json["audioplayer"],
      );

  Map<String, dynamic> toJson() => {
        "Voice_id": voiceId,
        "Voicename": voicename,
        "Voicedate": voicedate,
        "audioplayer": audioPlayer,
      };
}
