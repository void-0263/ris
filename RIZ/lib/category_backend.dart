// File: lib/category_backend.dart
// CORRECTED VERSION - Fixed ExamData/ExamDate constructor issues

import 'dart:convert';

class CategoryBackend {
  static List<CategoryData> getAllCategories() {
    return [
      // TNPSC
      CategoryData(
        name: 'TNPSC',
        fullName: 'Tamil Nadu Public Service Commission',
        color: 0xFFBDB76B,
        icon: '🏛️',
        jobRoles: {
          'Group 1': JobRoleData(
            name: 'Group 1',
            fullName: 'Combined Civil Services Examination - Group 1',
            exams: [
              ExamData(
                name: 'Preliminary Examination',
                type: 'Objective Type (OMR)',
                subjects: ['General Studies', 'Aptitude'],
                duration: '3 hours',
                totalMarks: 300,
              ),
              ExamData(
                name: 'Main Examination',
                type: 'Descriptive',
                subjects: ['GS I', 'GS II', 'GS III', 'Essay'],
                duration: '3 hours per paper',
                totalMarks: 1050,
              ),
              ExamData(
                name: 'Interview',
                type: 'Personality Test',
                subjects: ['General Knowledge', 'Personality'],
                duration: '30-45 minutes',
                totalMarks: 100,
              ),
            ],
            upcomingDates: [
              ExamDate(
                event: 'Official Notification Release',
                date: DateTime(2026, 6, 23),
                status: 'Expected',
              ),
              ExamDate(
                event: 'Preliminary Examination',
                date: DateTime(2026, 9, 6),
                status: 'Confirmed',
              ),
              ExamDate(
                event: 'Main Examination',
                date: DateTime(2026, 12, 5),
                endDate: DateTime(2026, 12, 9),
                status: 'Expected',
              ),
            ],
            studyLinks: [
              StudyLink(
                title: 'TNPSC Official Website',
                url: 'https://www.tnpsc.gov.in',
                type: 'Official',
              ),
            ],
          ),
          'Group 2': JobRoleData(
            name: 'Group 2',
            fullName: 'Combined Civil Services Examination - Group 2',
            exams: [
              ExamData(
                name: 'Preliminary Examination',
                type: 'Objective',
                subjects: ['General Studies', 'Aptitude'],
                duration: '3 hours',
                totalMarks: 300,
              ),
            ],
            upcomingDates: [
              ExamDate(
                event: 'Preliminary Examination',
                date: DateTime(2026, 10, 25),
                status: 'Confirmed',
              ),
            ],
            studyLinks: [],
          ),
          'Group 4': JobRoleData(
            name: 'Group 4',
            fullName: 'Combined Civil Services Examination - Group 4',
            exams: [
              ExamData(
                name: 'Written Examination',
                type: 'Objective (OMR)',
                subjects: ['General Studies', 'Tamil', 'English'],
                duration: '3 hours',
                totalMarks: 300,
              ),
            ],
            upcomingDates: [
              ExamDate(
                event: 'Written Examination',
                date: DateTime(2026, 12, 20),
                status: 'Confirmed',
              ),
            ],
            studyLinks: [],
          ),
        },
      ),

      // UPSC
      CategoryData(
        name: 'UPSC',
        fullName: 'Union Public Service Commission',
        color: 0xFF1976D2,
        icon: '🇮🇳',
        jobRoles: {
          'Civil Services': JobRoleData(
            name: 'Civil Services',
            fullName: 'IAS/IPS/IFS Examination',
            exams: [
              ExamData(
                name: 'Preliminary Examination',
                type: 'Objective (MCQ)',
                subjects: ['GS Paper I', 'CSAT Paper II'],
                duration: '2 hours per paper',
                totalMarks: 400,
              ),
              ExamData(
                name: 'Main Examination',
                type: 'Descriptive',
                subjects: ['Essay', 'GS I-IV', 'Optional'],
                duration: '3 hours per paper',
                totalMarks: 1750,
              ),
              ExamData(
                name: 'Interview',
                type: 'Personality Test',
                subjects: ['General Knowledge', 'Personality'],
                duration: '30-45 minutes',
                totalMarks: 275,
              ),
            ],
            upcomingDates: [
              ExamDate(
                event: 'Application End',
                date: DateTime(2026, 2, 24),
                status: 'Open',
              ),
              ExamDate(
                event: 'Preliminary Examination',
                date: DateTime(2026, 5, 24),
                status: 'Confirmed',
              ),
              ExamDate(
                event: 'Main Examination',
                date: DateTime(2026, 8, 21),
                endDate: DateTime(2026, 8, 25),
                status: 'Confirmed',
              ),
            ],
            studyLinks: [
              StudyLink(
                title: 'UPSC Official Website',
                url: 'https://www.upsc.gov.in',
                type: 'Official',
              ),
            ],
          ),
        },
      ),

      // SSC
      CategoryData(
        name: 'SSC',
        fullName: 'Staff Selection Commission',
        color: 0xFF7B1FA2,
        icon: '📝',
        jobRoles: {
          'CGL': JobRoleData(
            name: 'CGL',
            fullName: 'Combined Graduate Level',
            exams: [
              ExamData(
                name: 'Tier 1',
                type: 'Computer Based Test',
                subjects: ['Reasoning', 'GK', 'Quant', 'English'],
                duration: '60 minutes',
                totalMarks: 200,
              ),
              ExamData(
                name: 'Tier 2',
                type: 'Computer Based Test',
                subjects: ['Quant', 'English'],
                duration: '2 hours per paper',
                totalMarks: 400,
              ),
            ],
            upcomingDates: [
              ExamDate(
                event: 'Tier 1 Examination',
                date: DateTime(2026, 5, 15),
                endDate: DateTime(2026, 6, 15),
                status: 'Expected',
              ),
            ],
            studyLinks: [
              StudyLink(
                title: 'SSC Official Website',
                url: 'https://ssc.gov.in',
                type: 'Official',
              ),
            ],
          ),
        },
      ),

      // Banking
      CategoryData(
        name: 'Banking',
        fullName: 'Banking Sector Exams',
        color: 0xFFE65100,
        icon: '🏦',
        jobRoles: {
          'IBPS PO': JobRoleData(
            name: 'IBPS PO',
            fullName: 'Probationary Officer',
            exams: [],
            upcomingDates: [],
            studyLinks: [],
          ),
        },
      ),

      // Railways
      CategoryData(
        name: 'Railways',
        fullName: 'Railway Recruitment Board',
        color: 0xFF00695C,
        icon: '🚂',
        jobRoles: {},
      ),

      // Defence
      CategoryData(
        name: 'Defence',
        fullName: 'Defence Forces Recruitment',
        color: 0xFFD32F2F,
        icon: '⚔️',
        jobRoles: {},
      ),
    ];
  }

  static CategoryData? getCategory(String name) {
    try {
      return getAllCategories().firstWhere((cat) => cat.name == name);
    } catch (e) {
      return null;
    }
  }
}

// Data Models
class CategoryData {
  final String name;
  final String fullName;
  final int color;
  final String icon;
  final Map<String, JobRoleData> jobRoles;

  CategoryData({
    required this.name,
    required this.fullName,
    required this.color,
    required this.icon,
    required this.jobRoles,
  });
}

class JobRoleData {
  final String name;
  final String fullName;
  final List<ExamData> exams;
  final List<ExamDate> upcomingDates;
  final List<StudyLink> studyLinks;

  JobRoleData({
    required this.name,
    required this.fullName,
    required this.exams,
    required this.upcomingDates,
    required this.studyLinks,
  });
}

// ✅ FIXED: ExamData class
class ExamData {
  final String name;
  final String type;
  final List<String> subjects;
  final String duration;
  final int totalMarks;

  ExamData({
    required this.name,
    required this.type,
    required this.subjects,
    required this.duration,
    required this.totalMarks,
  });
}

// ✅ FIXED: ExamDate class (separate from ExamData)
class ExamDate {
  final String event;
  final DateTime date;
  final DateTime? endDate;
  final String status;

  ExamDate({
    required this.event,
    required this.date,
    this.endDate,
    required this.status,
  });
}

class StudyLink {
  final String title;
  final String url;
  final String type;

  StudyLink({required this.title, required this.url, required this.type});
}
