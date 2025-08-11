import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface SavedSearch { id: string; userId: string; query: string; tags: string[]; createdAt: string }

Deno.serve(async (req: Request) => {
  try {
    // TODO: use Supabase client with auth to fetch user's saved searches
    const userId = crypto.randomUUID(); // placeholder; extract from JWT in production
    const now = new Date().toISOString();
    const items: SavedSearch[] = [
      { id: crypto.randomUUID(), userId, query: "#ghosting", tags: ["red flag"], createdAt: now },
      { id: crypto.randomUUID(), userId, query: "near: Austin", tags: [], createdAt: now },
    ];
    return new Response(JSON.stringify(items), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
