/// Mutable drafts shared across multi-step flows (same pattern as ExamDraft).

class OnboardingDraft {
  String fullName = '';
  String email = '';
  String password = '';
  String title = '';
  String institutionName = '';
  String className = '';
  String grade = '';
  String section = '';
}

final onboardingDraft = OnboardingDraft();
