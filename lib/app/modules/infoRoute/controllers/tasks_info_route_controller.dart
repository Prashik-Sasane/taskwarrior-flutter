import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskwarrior/app/modules/home/controllers/home_controller.dart';
import 'package:taskwarrior/app/models/json/task.dart';

class TasksInfoRouteController extends GetxController {
  late String uuid;
  var task = Rxn<Task>();
  @override
  void onInit() {
     super.onInit();
    var arguments = Get.arguments;
    uuid = arguments[1] as String;
    // uuid = Get.arguments['uuid'];
    loadTask();
  }
  void loadTask() {
    var storageWidget = Get.find<HomeController>();
    var loadedTask = storageWidget.getTask(uuid);
    if (loadedTask != null) {
      task.value = loadedTask;
    } else {
      // Handle case where task is not found, e.g., show an error message
      print('Task with UUID $uuid not found.');
    }
  }

}
