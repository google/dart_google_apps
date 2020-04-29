@JS('Tasks')
library tasks;

import 'package:js/js.dart';

// https://developers.google.com/tasks/v1/reference/tasklists
@JS()
class Tasklists {
  external String get kind;

  external String get etag;

  external String get nextPageToken;

  external List<Tasklist> get items;

  external static Tasklists list([num maxResults, String pageToken]);

  external static Tasklist get(String tasklist);

  external static Tasklist insert(Tasklist resource);

  external static Tasklist update(Tasklist resource, String tasklist);

  external static void remove(String id);
}

@JS()
class Tasklist {
  external String get etag;

  external set etag(String etag);

  external String get id;

  external set id(String id);

  external String get kind;

  external set kind(String kind);

  external String get selfLink;

  external set selfLink(String selfLink);

  external String get title;

  external set title(String title);

  external String get updated;

  external set updated(String updated);
}

// https://developers.google.com/tasks/v1/reference/tasks
@JS()
class Tasks {
  external String get etag;

  external String get kind;

  external String get nextPageToken;

  external List<Task> get items;

  external static void clear(String tasklist);

  external static Task get(String tasklist, String task);

  external static Task insert(Task resource, String tasklist,
      [TaskOptions taskOptions]);

  external static Tasks list(String tasklist, [TaskOptions taskOptions]);

  external static Task move(String tasklist, String task,
      [TaskOptions taskOptions]);

  external static Task patch(Task resource, String tasklist, String task);

  external static void remove(String tasklist, String task);

  external static Task update(Task resource, String tasklist, String task);
}

@JS()
@anonymous
class TaskOptions {
  external String get completedMax;

  external String get completedMin;

  external String get dueMax;

  external String get dueMin;

  external num get maxResults;

  external String get pageToken;

  external bool get showCompleted;

  external bool get showDeleted;

  external bool get showHidden;

  external String get updatedMin;

  external String get parent;

  external String get previous;

  external factory TaskOptions(
      {String completedMax,
      String completedMin,
      String dueMax,
      String dueMin,
      num maxResults,
      String pageToken,
      bool showCompleted,
      bool showDeleted,
      bool showHidden,
      String updatedMin,
      String parent,
      String previous});
}

@JS()
class Task {
  external String get etag;

  external set etag(String etag);

  external String get kind;

  external set kind(String kind);

  external String get id;

  external set id(String id);

  external String get title;

  external set title(String title);

  external String get parent;

  external set parent(String parent);

  external String get position;

  external set position(String position);

  external String get notes;

  external set notes(String notes);

  external String get status;

  external set status(String status);

  external bool get deleted;

  external set deleted(bool deleted);

  external bool get hidden;

  external List<TaskLinks> get links;

  external String get selfLink;

  external set selfLink(String selfLink);

  external String get due;

  external set due(String due);

  external String get completed;

  external set completed(String completed);

  external String get updated;

  external set updated(String updated);
}

@JS()
class TaskLinks {
  external String get description;

  external String get link;

  external String get type;
}
