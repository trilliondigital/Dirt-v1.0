import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface SaveInterestsBody {
  interests: string[];
}

Deno.serve(async (req: Request) => {
  try {
    const body = (await req.json()) as SaveInterestsBody;
    if (!Array.isArray(body.interests)) {
      return new Response(JSON.stringify({ error: "interests must be an array" }), { status: 400 });
    }
    const interests = body.interests.map((s) => String(s)).filter((s) => s.trim().length > 0).slice(0, 50);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );

    const { data: userRes, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userRes.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    if (interests.length === 0) {
      return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
    }

    // Temporary persistence: store as saved_searches with a special prefix
    const rows = interests.map((i) => ({ user_id: userRes.user.id, query: `interest:${i}`, tags: [] as string[] }));
    const { error } = await supabase.from("saved_searches").insert(rows);
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
    return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
