/// Static legal & compliance documents rendered natively in the app (so they
/// are available offline and satisfy Google Play's in-app policy requirement).
/// Keep this in sync with the website pages under resources/views/web/legal/.
///
/// Replace the [bracketed placeholders] with your real details before release:
/// [Company Name], [App Name], [Support Email], [Phone Number],
/// [Registered Address], [Grievance Officer Name], [City], [State].
library;

class LegalSection {
  final String? heading;
  final List<String> paragraphs;
  final List<String> bullets;
  const LegalSection({this.heading, this.paragraphs = const [], this.bullets = const []});
}

class LegalDoc {
  final String slug;
  final String title;
  final String subtitle;
  final List<LegalSection> sections;
  const LegalDoc({required this.slug, required this.title, required this.subtitle, required this.sections});
}

/// All documents, in menu order.
const List<LegalDoc> kLegalDocs = [
  _privacy,
  _terms,
  _refund,
  _pricing,
  _contact,
];

LegalDoc? legalDocBySlug(String slug) {
  for (final d in kLegalDocs) {
    if (d.slug == slug) return d;
  }
  return null;
}

// ── Privacy Policy ──────────────────────────────────────────────────────────
const _privacy = LegalDoc(
  slug: 'privacy',
  title: 'Privacy Policy',
  subtitle: 'How we collect, use, share and protect your data.',
  sections: [
    LegalSection(paragraphs: [
      'This Privacy Policy is published under the Information Technology Act, 2000, the IT (Reasonable Security Practices) Rules, 2011, and the Digital Personal Data Protection Act, 2023 ("DPDP Act"). By using [App Name] you consent to the practices described here.',
    ]),
    LegalSection(heading: '1. Who we are', paragraphs: [
      '[App Name] is owned and operated by [Company Name], registered in India at [Registered Address]. We are the "Data Fiduciary" for your personal data. For any privacy query, contact our Grievance Officer at [Support Email].',
    ]),
    LegalSection(heading: '2. Information we collect', bullets: [
      'Account information — name, email, mobile number, password (stored hashed), and basic Google/Facebook profile if you use social login.',
      'Profile & learning data — preferences, bookmarks, notes, test attempts, scores, streaks and progress.',
      'Transaction information — plan, order IDs and payment status. We do NOT store your full card/UPI/bank details; the payment gateway handles these.',
      'Device & technical data — device model, OS, app version, IP address and a Firebase push token (used only for notifications).',
      'Usage & diagnostics — feature usage and crash logs, to keep the service reliable.',
    ]),
    LegalSection(heading: '3. How we use your information', bullets: [
      'Create and secure your account and authenticate you.',
      'Deliver the study material, tests and features you request.',
      'Process subscriptions and provide receipts and support.',
      'Personalise your learning and show progress.',
      'Send service messages and, where enabled, notifications.',
      'Maintain security, prevent fraud, and comply with law.',
    ]),
    LegalSection(heading: '4. Consent (DPDP Act 2023)', paragraphs: [
      'We process your data based on the consent you give at registration and for the "legitimate uses" permitted under the DPDP Act. You may withdraw consent at any time; this will not affect prior processing and may limit some features.',
    ]),
    LegalSection(heading: '5. How we share your information', paragraphs: [
      'We do NOT sell your data. We share it only with trusted processors to run the platform:',
    ], bullets: [
      'Payment gateways (e.g. Razorpay and other RBI-authorised gateways) — to process payments.',
      'Cloud hosting & infrastructure — to run the app and database.',
      'Google Firebase — for push notifications and crash diagnostics.',
      'Communication providers — email/SMS/WhatsApp for OTPs and account messages.',
      'Legal & safety authorities — where required by law or to protect our rights and users.',
    ]),
    LegalSection(heading: '6. Data retention', paragraphs: [
      'We keep your data while your account is active or as needed to provide the service, and thereafter only as legally required (e.g. tax records). On account deletion we delete or anonymise your personal data within [30] days, except records we must retain by law.',
    ]),
    LegalSection(heading: '7. Your rights', bullets: [
      'Access a summary of your data and how it is processed.',
      'Correct or update your data (Profile → Edit Profile).',
      'Erase your data and delete your account (see Section 8).',
      'Withdraw consent to further processing.',
      'Raise a grievance and nominate another person to exercise your rights.',
    ]),
    LegalSection(heading: '8. Delete your account & data', paragraphs: [
      'You can request deletion in two ways:',
    ], bullets: [
      'In-app: Profile → Edit Profile → Delete Account.',
      'By email: write to [Support Email] from your registered email with subject "Delete My Account".',
    ]),
    LegalSection(heading: '9. Google Play Data Safety', bullets: [
      'Data collected: name, email, phone, app activity, learning progress, device identifiers and diagnostics.',
      'Data shared: only with payment and infrastructure providers; never sold or shared for advertising.',
      'Security: encrypted in transit (TLS); passwords and sensitive fields hashed/encrypted at rest.',
      'Deletion: available in-app and by email (Section 8).',
    ]),
    LegalSection(heading: '10. Children’s privacy', paragraphs: [
      'The app is intended for users aged [18]+ (or a minor with verifiable parental consent as required by the DPDP Act). We do not knowingly collect data from children without such consent.',
    ]),
    LegalSection(heading: '11. Security', paragraphs: [
      'We use TLS encryption, hashed passwords, access controls and signed URLs for private files. No method is 100% secure, so we cannot guarantee absolute security.',
    ]),
    LegalSection(heading: '12. Changes & contact', paragraphs: [
      'We may update this policy; material changes will be notified in-app or by email.',
      'Grievance Officer: [Grievance Officer Name], [Company Name], [Registered Address], [Support Email], [Phone Number]. We acknowledge grievances within 24 hours and resolve them within 15 days.',
    ]),
  ],
);

// ── Terms & Conditions ──────────────────────────────────────────────────────
const _terms = LegalDoc(
  slug: 'terms',
  title: 'Terms & Conditions',
  subtitle: 'The rules governing your use of the app.',
  sections: [
    LegalSection(paragraphs: [
      'These Terms are a binding agreement between you and [Company Name] governing your use of the [App Name] app and website (the "Platform"). By using the Platform you agree to these Terms. If you do not agree, do not use the Platform.',
    ]),
    LegalSection(heading: '1. Eligibility', paragraphs: [
      'You must be at least [18] years old (or have guardian consent) and able to contract under Indian law. Information you provide must be true and complete.',
    ]),
    LegalSection(heading: '2. Your account', bullets: [
      'You are responsible for your credentials and all activity under your account.',
      'Accounts are personal and non-transferable; one account per person.',
      'A single active session/device is allowed at a time for security.',
      'Tell us immediately of any unauthorised use.',
    ]),
    LegalSection(heading: '3. Subscriptions & payments', bullets: [
      'Some features need a paid subscription. Prices are in INR, inclusive of applicable taxes unless stated.',
      'Payments are handled by RBI-authorised gateways; their terms also apply.',
      'Refunds and cancellations follow our Refund & Cancellation Policy.',
      'We may change prices prospectively without affecting an active term.',
    ]),
    LegalSection(heading: '4. Licence & acceptable use', paragraphs: [
      'We grant you a limited, personal, non-transferable, revocable licence to use the Platform for your own exam preparation. You agree not to:',
    ], bullets: [
      'Copy, record, scrape, redistribute, resell or publicly display our content.',
      'Share your account or bypass paywalls, security or content protection.',
      'Upload unlawful or infringing content, or misuse support channels.',
      'Use bots/automation, or reverse-engineer, hack or disrupt the Platform.',
    ]),
    LegalSection(heading: '5. Intellectual property', paragraphs: [
      'All content (text, notes, questions, tests, videos, graphics, logos, software, design) is owned by or licensed to [Company Name] and protected by law. The [App Name] name and logo are our trademarks and may not be used without written permission.',
    ]),
    LegalSection(heading: '6. Disclaimers', bullets: [
      'The Platform provides educational content only and is NOT affiliated with or endorsed by the UPSC or any government body.',
      'We do NOT guarantee any result, rank or selection.',
      'Content is provided "as is"; verify important facts (dates, notifications, cut-offs) with official sources.',
    ]),
    LegalSection(heading: '7. Limitation of liability', paragraphs: [
      'To the maximum extent permitted by law, [Company Name] is not liable for any indirect, incidental or consequential damages, or loss of data/profits. Our total liability for any claim will not exceed the amount you paid us in the [three (3)] months before the claim.',
    ]),
    LegalSection(heading: '8. Termination', paragraphs: [
      'We may suspend or terminate access for breach of these Terms, suspected fraud, or as required by law. You may stop using the Platform and delete your account at any time.',
    ]),
    LegalSection(heading: '9. Governing law & disputes', paragraphs: [
      'These Terms are governed by the laws of India. Courts at [City], [State] have exclusive jurisdiction, subject to amicable resolution via our Grievance Officer and, failing that, arbitration under the Arbitration and Conciliation Act, 1996, seated at [City], [State].',
    ]),
    LegalSection(heading: '10. Contact', paragraphs: [
      '[Company Name], [Registered Address], [Support Email], [Phone Number].',
    ]),
  ],
);

// ── Refund & Cancellation ───────────────────────────────────────────────────
const _refund = LegalDoc(
  slug: 'refund',
  title: 'Refund & Cancellation Policy',
  subtitle: 'How cancellations and refunds work.',
  sections: [
    LegalSection(paragraphs: [
      '[App Name] provides digital subscription services that grant immediate access upon successful payment. Because access is delivered instantly and consumed digitally, the following applies.',
    ]),
    LegalSection(heading: '1. Nature of the service', paragraphs: [
      'All plans are digital subscriptions delivered electronically. Nothing is shipped. Access activates automatically once payment is confirmed.',
    ]),
    LegalSection(heading: '2. No-refund policy (limited exceptions)', paragraphs: [
      'As a general rule, all subscription fees are non-refundable once the subscription is activated and access is granted. We will consider a refund only in these cases:',
    ], bullets: [
      'Duplicate payment — charged more than once for the same order.',
      'Payment deducted but access not granted and not fixable by support.',
      'Proven, unresolved technical failure making the paid service materially inaccessible on our side.',
    ]),
    LegalSection(heading: '3. Not eligible', paragraphs: [
      'Refunds are not provided for change of mind, lack of usage, dissatisfaction with results/rank, or failure to cancel before renewal.',
    ]),
    LegalSection(heading: '4. Cancellation', bullets: [
      'Cancel anytime from Profile → Subscription or by contacting support; this stops future auto-renewal.',
      'You keep access until the end of the current paid term; no pro-rata refund for the unused period.',
      'Where auto-renewal applies, cancel at least [24] hours before renewal to avoid the next charge.',
    ]),
    LegalSection(heading: '5. How to request a refund', paragraphs: [
      'Email [Support Email] from your registered email within [7] days of the transaction, with your order ID and a description of the issue.',
    ]),
    LegalSection(heading: '6. Processing', paragraphs: [
      'Approved refunds are returned to the original payment method within [5–7] business days of approval; the time to reflect depends on your bank/card issuer.',
    ]),
    LegalSection(heading: '7. Contact', paragraphs: [
      '[Company Name], [Support Email], [Phone Number].',
    ]),
  ],
);

// ── Pricing & Service Delivery ──────────────────────────────────────────────
const _pricing = LegalDoc(
  slug: 'pricing',
  title: 'Pricing & Service Delivery',
  subtitle: 'What plans cost and how you receive access.',
  sections: [
    LegalSection(heading: '1. Pricing', bullets: [
      'All prices are in Indian Rupees (INR / ₹).',
      'Displayed prices are inclusive of applicable taxes (e.g. GST) unless stated at checkout.',
      'Current plans and prices are shown in Profile → Plans. Changes apply prospectively and do not affect an active subscription.',
    ]),
    LegalSection(heading: '2. What you get', paragraphs: [
      'A paid subscription unlocks the premium features described for that plan (study material, notes, current affairs, PYQs, test series, analytics). Free features remain available without payment.',
    ]),
    LegalSection(heading: '3. How the service is delivered', bullets: [
      '[App Name] is a digital service — there is no physical shipment.',
      'Access is delivered electronically to your registered account via the app and website.',
    ]),
    LegalSection(heading: '4. Delivery timeline', paragraphs: [
      'Your subscription activates automatically and immediately on successful payment — usually within seconds and no later than [24] hours. If payment succeeds but access is not activated within this window, contact support and we will fix it or refund per the Refund & Cancellation Policy.',
    ]),
    LegalSection(heading: '5. Payment methods', paragraphs: [
      'We accept payments through RBI-authorised gateways supporting UPI, cards, net-banking and wallets as available at checkout. We do not store your full payment credentials.',
    ]),
    LegalSection(heading: '6. Taxes & invoices', paragraphs: [
      'Taxes are charged as required by Indian law. A receipt is provided for every successful transaction. For a GST invoice, contact us.',
    ]),
    LegalSection(heading: '7. Contact', paragraphs: [
      '[Company Name], [Registered Address], [Support Email], [Phone Number].',
    ]),
  ],
);

// ── Contact Us ──────────────────────────────────────────────────────────────
const _contact = LegalDoc(
  slug: 'contact',
  title: 'Contact Us',
  subtitle: 'Reach us for support, billing or grievances.',
  sections: [
    LegalSection(heading: 'Business details', bullets: [
      'Registered name: [Company Name]',
      'Registered address: [Registered Address]',
      'Email: [Support Email]',
      'Phone: [Phone Number]',
      'Support hours: [Mon–Sat, 10:00 AM – 6:00 PM IST]',
    ]),
    LegalSection(heading: 'Grievance Officer', paragraphs: [
      'Under the IT Act 2000 and DPDP Act 2023:',
    ], bullets: [
      'Name: [Grievance Officer Name]',
      'Email: [Support Email]',
      'Address: [Registered Address]',
    ]),
    LegalSection(paragraphs: [
      'We aim to respond within [1–2] business days.',
    ]),
  ],
);
