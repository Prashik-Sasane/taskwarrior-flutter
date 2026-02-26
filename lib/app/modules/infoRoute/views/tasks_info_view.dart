import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:built_collection/built_collection.dart';

import 'package:taskwarrior/app/models/json/task.dart';
import 'package:taskwarrior/app/models/json/annotation.dart';
import 'package:taskwarrior/app/modules/home/controllers/home_controller.dart';
import 'package:taskwarrior/app/modules/infoRoute/controllers/tasks_info_route_controller.dart';
import 'package:taskwarrior/app/utils/themes/theme_extension.dart';
import 'package:taskwarrior/app/utils/app_settings/app_settings.dart';
import 'package:taskwarrior/app/modules/infoRoute/bindings/tasks_info_route_building.dart';
class TasksInfoView extends StatelessWidget {
  const TasksInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TasksInfoRouteController>();
    final tColors =
        Theme.of(context).extension<TaskwarriorColorTheme>()!;

    return Scaffold(
      backgroundColor: tColors.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: tColors.primaryBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text("task info"),
      ),
      body: Obx(() {
        final task = controller.task.value;

        if (task == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildBody(task, controller, tColors);
      }),
    );
  }

  Widget _buildBody(
      Task task,
      TasksInfoRouteController controller,
      TaskwarriorColorTheme tColors) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ---------------- TASK CARD ----------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Title
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: tColors.primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// ID / Status / Urgency
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("id: ${task.id}",
                        style: const TextStyle(color: Colors.grey)),
                    Text(task.status),
                    Text(
                      "urg: ${task.urgency?.toStringAsFixed(2) ?? "0.00"}",
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _infoLine("entry", formatDate(task.entry)),
                const SizedBox(height: 10),
                _infoLine("mod",
                    task.modified != null ? formatDate(task.modified!) : "-"),
                const SizedBox(height: 10),
                _infoLine("due",
                    task.due != null ? formatDate(task.due!) : "-"),
                const SizedBox(height: 10),
                _infoLine("project", task.project ?? "-"),
                const SizedBox(height: 10),
                _infoLine("priority", task.priority ?? "-"),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// ---------------- ADD ANNOTATION BUTTON ----------------
          Center(
            child: ElevatedButton(
              onPressed: () =>
                  _showAddAnnotationDialog(task, controller),
              child: const Text("new annotation"),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Annotations",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          /// ---------------- ANNOTATION LIST ----------------
          if (task.annotations != null &&
              task.annotations!.isNotEmpty)
            ...task.annotations!
                .map(
                  (a) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.grey.shade600),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.description ?? "",
                          style: TextStyle(
                              color:
                                  tColors.primaryTextColor),
                        ),
                        if (a.entry != null)
                          Text(
                            formatDate(a.entry!),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                )
                .toList()
          else
            const Text("No annotations"),
        ],
      ),
    );
  }

  /// ---------------- ADD ANNOTATION DIALOG ----------------
  void _showAddAnnotationDialog(
      Task task, TasksInfoRouteController controller) {

    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("New Annotation"),
        content: TextField(
          controller: textController,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isEmpty) {
                Get.back();
                return;
              }

              final homeController =
                  Get.find<HomeController>();

              /// SAFE BUILT_VALUE UPDATE
              final updatedTask = task.rebuild((b) {
                b.annotations.add(
                  Annotation((a) => a
                    ..description = textController.text.trim()
                    ..entry = DateTime.now().toUtc()),
                );
              });
              homeController.mergeTask(updatedTask);

              /// Reload fresh task
              controller.loadTask();

              Get.back();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  /// ---------------- DATE FORMAT ----------------
  String formatDate(DateTime date) {
    final format = AppSettings.use24HourFormatRx.value
        ? 'EEE, yyyy-MM-dd HH:mm:ss'
        : 'EEE, yyyy-MM-dd hh:mm:ss a';

    return DateFormat(format).format(date.toLocal());
  }

  /// ---------------- PRIORITY COLOR ----------------
  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'H':
        return Colors.red;
      case 'M':
        return Colors.orange;
      case 'L':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _infoLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14),
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(color: Colors.grey),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}