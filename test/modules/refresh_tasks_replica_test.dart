import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:taskwarrior/app/modules/home/controllers/home_controller.dart';
import 'package:taskwarrior/app/v3/champion/models/task_for_replica.dart';
import 'package:taskwarrior/app/modules/splash/controllers/splash_controller.dart';

/// ------------------------------------------------------------
/// Minimal fake SplashController
/// We ONLY implement what HomeController actually uses.
/// ------------------------------------------------------------
class FakeSplashController extends SplashController {
  @override
  final baseDirectory = Rx<Directory>(Directory.systemTemp);

  @override
  final currentProfile = 'test-profile'.obs;

  @override
  String getMode(String profile) => "TW3";
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomeController controller;

  setUp(() {
    Get.reset();

    // 🔑 Register required dependency for HomeController
    Get.put<SplashController>(
      FakeSplashController(),
      permanent: true,
    );

    controller = HomeController();

    // Enable replica mode
    controller.taskchampion.value = true;
    controller.taskReplica.value = true;

    // Default filters
    controller.pendingFilter.value = false;
    controller.deletedFilter.value = false;
  });

  test(
      'Replica mode: shows only pending tasks when pendingFilter is enabled',
      () {
    controller.pendingFilter.value = true;

    controller.tasksFromReplica.value = [
      TaskForReplica(
        uuid: '1',
        status: 'pending',
        description: 'Pending task',
        modified: 2,
      ),
      TaskForReplica(
        uuid: '2',
        status: 'completed',
        description: 'Completed task',
        modified: 1,
      ),
    ];

    controller.refreshTasksforTest();

    expect(controller.queriedTasks.length, 1);
    expect(controller.queriedTasks.first.description, 'Pending task');
    expect(controller.queriedTasks.first.status, 'pending');
  });

  test(
      'Replica mode: shows only completed tasks when pendingFilter is disabled',
      () {
    controller.pendingFilter.value = false;

    controller.tasksFromReplica.value = [
      TaskForReplica(
        uuid: '1',
        status: 'pending',
        description: 'Pending task',
        modified: 1,
      ),
      TaskForReplica(
        uuid: '2',
        status: 'completed',
        description: 'Completed task',
        modified: 2,
      ),
    ];

    controller.refreshTasksforTest();

    expect(controller.queriedTasks.length, 1);
    expect(controller.queriedTasks.first.description, 'Completed task');
    expect(controller.queriedTasks.first.status, 'completed');
  });

  test('Replica mode: deleted filter is ignored', () {
    controller.deletedFilter.value = true; // should be force-disabled

    controller.tasksFromReplica.value = [
      TaskForReplica(
        uuid: '1',
        status: 'pending',
        description: 'Pending task',
        modified: 1,
      ),
      TaskForReplica(
        uuid: '2',
        status: 'completed',
        description: 'Completed task',
        modified: 2,
      ),
    ];

    controller.refreshTasksforTest();

    // deletedFilter must be reset
    expect(controller.deletedFilter.value, false);

    // default → completed
    expect(controller.queriedTasks.length, 1);
    expect(controller.queriedTasks.first.status, 'completed');
  });

  test(
      'Replica mode: deduplicates tasks by uuid using latest modified',
      () {
    controller.pendingFilter.value = true;

    controller.tasksFromReplica.value = [
      TaskForReplica(
        uuid: '1',
        status: 'pending',
        description: 'Old version',
        modified: 1,
      ),
      TaskForReplica(
        uuid: '1',
        status: 'pending',
        description: 'New version',
        modified: 5,
      ),
    ];

    controller.refreshTasksforTest();

    expect(controller.queriedTasks.length, 1);
    expect(controller.queriedTasks.first.description, 'New version');
  });
}
