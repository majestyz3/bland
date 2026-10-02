// DEMO MOCK: stands in for SCAN's member-management API. Synthetic plan data; test member is the demo builder.
// Template placeholders (${member_id_suffix}, ${dob_mmddyyyy}, ${dob_yyyymmdd}, ${member_first_name}, ${member_full_name}) are filled by Terraform templatefile().
export default {
  async fetch(request) {
    const j = await request.json();
    const id = String(j.member_id || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
    const dob = String(j.date_of_birth || '').replace(/[^0-9]/g, '');
    const idOk = id.endsWith('${member_id_suffix}');
    const dobOk = dob === '${dob_mmddyyyy}' || dob === '${dob_yyyymmdd}';
    if (!idOk || !dobOk) {
      return Response.json({ authenticated: false, reason: 'Member ID and date of birth could not be verified together.' });
    }
    return Response.json({
      authenticated: true,
      demo_data: true,
      member_first_name: '${member_first_name}',
      member_name: '${member_full_name}',
      plan_name: 'SCAN Demo Advantage',
      plan_status: 'Active',
      plan_changed: false,
      pcp: 'Dr. Demo Provider',
      id_card_status: 'Active',
      pharmacy_network: 'DemoRx Network',
      benefits_summary: 'DEMO benefits for SCAN Demo Advantage (in-network): primary care visit $0 copay; specialist visit $15 copay; preventive dental two cleanings and exams per year at $0; one routine eye exam per year at $0 plus a $150 annual eyewear allowance; DemoFit gym membership at no cost. Anything not listed here is not verified.'
    });
  }
}
