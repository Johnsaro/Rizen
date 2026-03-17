import 'package:flutter_dotenv/flutter_dotenv.dart';

// Supabase credentials loaded securely from .env
final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

// App version — bump this on every release. Compared against Supabase app_config
// to trigger force-update or soft-update prompts.
const appVersion = '2.0.0';
