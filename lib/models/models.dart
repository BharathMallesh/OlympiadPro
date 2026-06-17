import 'dart:typed_data';
import 'package:flutter/material.dart';

enum ExamStatus { draft, published, gradingNeeded, completed }

/// Parsing/review state of a single question in the AI review flow.
enum QStatus { parsed, reviewNeeded }

class QuestionOption {
  QuestionOption(this.text, {this.correct = false});
  String text;
  bool correct;
}

/// An editable question produced by the AI parser. Mutable so the edit screen
/// can write changes straight back into the shared store.
class QuestionItem {
  QuestionItem({
    required this.label,
    required this.prompt,
    required this.type,
    required this.status,
    List<QuestionOption>? options,
    List<Uint8List>? images,
    List<String>? imageUrls,
    this.warning,
    this.hasGraph = false,
    this.id,
    this.marks = 4,
    this.subject,
    this.topic,
  })  : options = options ?? [],
        images = images ?? [],
        imageUrls = imageUrls ?? [];

  final String label; // e.g. "Q1"
  String prompt; // question body (LaTeX/plain)
  String type; // Multiple Choice / Numeric / Short Answer
  QStatus status;
  final List<QuestionOption> options;
  final List<Uint8List> images; // attachments added from the device
  final List<String> imageUrls; // Cloudinary URLs already on the backend
  String? warning;
  bool hasGraph;
  String? id; // backend UUID; null until persisted
  int marks;
  String? subject;
  String? topic;

  /// Backend `qtype` ↔ display label.
  static const _typeMap = {
    'multiple_choice': 'Multiple Choice',
    'numeric': 'Numeric',
    'short_answer': 'Short Answer',
    'long_answer': 'Long Answer',
  };

  String get qtype => _typeMap.entries
      .firstWhere((e) => e.value == type,
          orElse: () => const MapEntry('short_answer', ''))
      .key;

  factory QuestionItem.fromApi(Map<String, dynamic> j, int position) {
    final options = (j['options'] as List? ?? [])
        .map((o) => QuestionOption(o['text'] as String? ?? '',
            correct: o['correct'] as bool? ?? false))
        .toList();
    return QuestionItem(
      id: j['id'] as String?,
      label: 'Q$position',
      prompt: j['prompt'] as String? ?? '',
      type: _typeMap[j['qtype']] ?? 'Short Answer',
      status: (j['status'] == 'review_needed')
          ? QStatus.reviewNeeded
          : QStatus.parsed,
      options: options,
      imageUrls: (j['image_urls'] as List? ?? []).cast<String>(),
      warning: j['warning'] as String?,
      hasGraph: j['has_graph'] as bool? ?? false,
      marks: (j['marks'] as num?)?.toInt() ?? 4,
      subject: j['subject'] as String?,
      topic: j['topic'] as String?,
    );
  }

  Map<String, dynamic> toApi() => {
        'prompt': prompt,
        'qtype': qtype,
        'subject': subject,
        'topic': topic,
        'marks': marks,
        'status': status == QStatus.reviewNeeded ? 'review_needed' : 'parsed',
        'warning': warning,
        'has_graph': hasGraph,
        'options': [
          for (final o in options) {'text': o.text, 'correct': o.correct}
        ],
      };
}

class Exam {
  Exam({
    required this.title,
    required this.board,
    required this.status,
    this.duration = 90,
    this.format = 'Mock Exam',
    this.description = '',
    this.questions = 30,
    this.marks = 120,
    this.submissions = 0,
    this.totalStudents = 48,
    this.subtitle = '',
  });

  String title;
  String board;
  ExamStatus status;
  int duration;
  String format;
  String description;
  int questions;
  int marks;
  int submissions;
  int totalStudents;
  String subtitle;
}

class Student {
  const Student(
    this.name,
    this.id, {
    this.tag = '',
    this.score,
    this.trend = const [0.5, 0.6, 0.55, 0.7, 0.65, 0.8, 0.78],
    this.color,
    this.status = '',
  });
  final String name;
  final String id;
  final String tag;
  final int? score;
  final List<double> trend;
  final Color? color;
  final String status;
}

class Submission {
  const Submission(this.student, this.submittedAgo, this.score, this.graded);
  final Student student;
  final String submittedAgo;
  final int? score;
  final bool graded;
}

class TopicScore {
  const TopicScore(this.name, this.score, this.target);
  final String name;
  final double score; // 0..1
  final double target;
}
