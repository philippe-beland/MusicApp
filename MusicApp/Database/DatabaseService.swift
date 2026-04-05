import Supabase
import Foundation

let supabase = SupabaseClient(
      supabaseURL: URL(string: Secrets.supabaseURL.rawValue)!,
      supabaseKey: Secrets.apiKey.rawValue
)



