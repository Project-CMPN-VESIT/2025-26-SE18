// Supabase Edge Function: create-user
// Replaces the Firebase 'createUser' function.
// Deploy with: supabase functions deploy create-user

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // 1. Handle CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, password, name, role, phone, zone, centre } = await req.json()

    // 2. Initialize Supabase Admin Client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // 3. Create Auth User
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, role: role || 'teacher' }
    })

    if (authError) throw authError

    // 4. Update the matching profile (Trigger handles initial creation, we add details)
    // Small delay to ensure DB trigger fired
    await new Promise(resolve => setTimeout(resolve, 500)); 

    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({ 
        phone: phone || '', 
        zone: zone || '', 
        centre: centre || '' 
      })
      .eq('id', authData.user.id)

    if (profileError) console.error('Profile update error:', profileError)

    return new Response(
      JSON.stringify({ success: true, uid: authData.user.id }),
      { 
        headers: { ...corsHeaders, "Content-Type": "application/json" }, 
        status: 200 
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, "Content-Type": "application/json" }, 
        status: 400 
      }
    )
  }
})
