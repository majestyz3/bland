// DEMO MOCK: stands in for SCAN's ID card fulfillment API. No real system is changed.
export default {
  async fetch(request) {
    const j = await request.json();
    const id = String(j.member_id || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
    if (!id.endsWith('${member_id_suffix}')) {
      return Response.json({ success: false, status: 'Request not submitted: member could not be matched. Offer Member Services.' });
    }
    return Response.json({
      success: true,
      demo_data: true,
      confirmation_number: 'DEMO-ID-4821',
      delivery_method: 'Mail to address on file',
      delivery_window: '7 to 10 business days',
      status: 'Replacement requested'
    });
  }
}
