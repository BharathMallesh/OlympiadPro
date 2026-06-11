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
    this.warning,
    this.hasGraph = false,
  })  : options = options ?? [],
        images = images ?? [];

  final String label; // e.g. "Q1"
  String prompt; // question body (LaTeX/plain)
  String type; // Multiple Choice / Numeric / Short Answer
  QStatus status;
  final List<QuestionOption> options;
  final List<Uint8List> images; // attachments added from the device
  String? warning;
  bool hasGraph;
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
