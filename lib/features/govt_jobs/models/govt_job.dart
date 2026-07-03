class GovtJob {
  final int id;
  final String title;
  final String slug;
  final String? organization;
  final String? organizationShort;
  final String? category;
  final String? state;
  final String? qualification;
  final String? advertisementNo;
  final int? totalVacancies;
  final String? ageLimit;
  final String? salary;
  final String? selectionProcess;
  final String? description;
  final String? applicationStartDate;
  final String? lastDate;
  final String? examDate;
  final String? notificationPdfUrl;
  final String? officialWebsiteUrl;
  final String? applicationLink;
  final bool isExpired;
  final bool isClosingSoon;

  const GovtJob({
    required this.id,
    required this.title,
    required this.slug,
    this.organization,
    this.organizationShort,
    this.category,
    this.state,
    this.qualification,
    this.advertisementNo,
    this.totalVacancies,
    this.ageLimit,
    this.salary,
    this.selectionProcess,
    this.description,
    this.applicationStartDate,
    this.lastDate,
    this.examDate,
    this.notificationPdfUrl,
    this.officialWebsiteUrl,
    this.applicationLink,
    this.isExpired = false,
    this.isClosingSoon = false,
  });

  factory GovtJob.fromJson(Map<String, dynamic> j) => GovtJob(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    slug: j['slug'] as String? ?? '',
    organization: j['organization'] as String?,
    organizationShort: j['organization_short'] as String?,
    category: j['category'] as String?,
    state: j['state'] as String?,
    qualification: j['qualification'] as String?,
    advertisementNo: j['advertisement_no'] as String?,
    totalVacancies: j['total_vacancies'] as int?,
    ageLimit: j['age_limit'] as String?,
    salary: j['salary'] as String?,
    selectionProcess: j['selection_process'] as String?,
    description: j['description'] as String?,
    applicationStartDate: j['application_start_date'] as String?,
    lastDate: j['last_date'] as String?,
    examDate: j['exam_date'] as String?,
    notificationPdfUrl: j['notification_pdf_url'] as String?,
    officialWebsiteUrl: j['official_website_url'] as String?,
    applicationLink: j['application_link'] as String?,
    isExpired: j['is_expired'] == true,
    isClosingSoon: j['is_closing_soon'] == true,
  );
}

class JobCategoryLite {
  final String name;
  final String slug;
  const JobCategoryLite({required this.name, required this.slug});

  factory JobCategoryLite.fromJson(Map<String, dynamic> j) => JobCategoryLite(
    name: j['name'] as String? ?? '',
    slug: j['slug'] as String? ?? '',
  );
}
