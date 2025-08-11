import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface SaveBody { query: string; tags?: string[] }

Deno.serve(async (req: Request) => {
  try {
    const body = (await req.json()) as SaveBody;
    if (!body.query || !body.query.trim()) {
      return new Response(JSON.stringify({ error: "Missing query" }), { status: 400 });
    }
    // TODO: insert into saved_searches for auth user
    return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
