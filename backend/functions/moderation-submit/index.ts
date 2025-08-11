import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface SubmitBody {
  post_id: string;
  reason: string;
  notes?: string | null;
}

Deno.serve(async (req: Request) => {
  try {
    const body = (await req.json()) as SubmitBody;
    if (!body.post_id || !body.reason) {
      return new Response(JSON.stringify({ error: "Missing post_id or reason" }), { status: 400 });
    }

    const createdAt = new Date().toISOString();
    const record = {
      id: crypto.randomUUID(),
      postId: body.post_id,
      reason: body.reason,
      createdAt,
      status: "pending",
      notes: body.notes ?? null,
    };

    // TODO: insert into reports table
    return new Response(JSON.stringify(record), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
