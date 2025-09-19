import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface SaveBody { query: string; tags?: string[] }

Deno.serve(async (req: Request) => {
  try {
    const body = (await req.json()) as SaveBody;
    const query = (body.query || "").trim();
    if (!query) {
      return new Response(JSON.stringify({ error: "Missing query" }), { status: 400 });
    }
    const tags = Array.isArray(body.tags) ? body.tags : [];

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );

    const { data: userRes, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userRes.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const { data, error } = await supabase
      .from("saved_searches")
      .insert({ user_id: userRes.user.id, query, tags })
      .select("id, created_at")
      .single();
    if (error || !data) {
      return new Response(JSON.stringify({ error: error?.message ?? "Insert failed" }), { status: 500 });
    }

    return new Response(JSON.stringify({ id: data.id, createdAt: data.created_at }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
