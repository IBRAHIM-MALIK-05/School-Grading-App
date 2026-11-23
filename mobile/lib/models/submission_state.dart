// lib/models/submission_state.dart
// The 3 states a subject's marks can be in for one class.

enum SubmissionState { notUploaded, inProgress, submitted }

// Works out the state from simple numbers.
SubmissionState submissionStateFrom({
  required int enteredCount,
  required int studentCount,
  required DateTime? submittedAt,
}) {
  if (submittedAt != null) return SubmissionState.submitted;
  if (enteredCount == 0) return SubmissionState.notUploaded;
  return SubmissionState.inProgress;
}
