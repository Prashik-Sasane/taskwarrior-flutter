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
   final homeController = Get.find<HomeController>();
   final loadedTask = homeController.getTask(uuid);
    task.value = loadedTask;
  }

}