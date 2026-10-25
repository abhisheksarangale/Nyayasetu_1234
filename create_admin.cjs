const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://hadmehbhswpfxglajist.supabase.co';
const supabaseServiceKey = 'sb_secret_JXlvxpT0Nb9iB0yGM9_HLg_rSGWv0Hp';

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function createAdmin() {
  const email = 'vishnughadigaonkar10b@gmail.com';
  const password = 'vishnu@13';

  console.log('Creating user in Auth...');
  
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email: email,
    password: password,
    email_confirm: true
  });

  if (authError) {
    if (authError.message.includes('already registered')) {
        console.log('User already exists. Fetching user ID...');
        const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers();
        if (usersError) {
           console.error('Error listing users:', usersError);
           return;
        }
        const existingUser = usersData.users.find(u => u.email === email);
        if (existingUser) {
           console.log('Found existing user:', existingUser.id);
           await updateProfile(existingUser.id, email);
        } else {
           console.log('Could not find existing user in list.');
        }
        return;
    } else {
        console.error('Error creating user:', authError);
        return;
    }
  }

  const userId = authData.user.id;
  console.log('User created with ID:', userId);

  await updateProfile(userId, email);
}

async function updateProfile(userId, email) {
  console.log('Updating profile table...');
  const { data: profileData, error: profileError } = await supabase
    .from('profiles')
    .upsert({
      id: userId,
      role: 'admin',
      is_active: true,
      email: email,
      display_name: 'Admin Vishnu',
      created_at: new Date().toISOString()
    })
    .select();

  if (profileError) {
    console.error('Error updating profile:', profileError);
  } else {
    console.log('Profile updated successfully!', profileData);
  }
}

createAdmin();
