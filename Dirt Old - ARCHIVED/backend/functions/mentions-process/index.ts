import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json().catch(() => ({}));
    // Expected: { post_id: string, mentions: string[], content?: string }
    const { post_id, mentions } = payload as { post_id?: string; mentions?: string[] };
    if (!post_id || !Array.isArray(mentions)) {
      return new Response(JSON.stringify({ processed: false, error: "invalid_payload" }), {
        headers: { "Content-Type": "application/json" },
        status: 400,
      });
    }

    // TODO: insert notifications for mentioned users once user identity mapping exists
    // For now, return success to let client proceed.
    return new Response(JSON.stringify({ processed: true }), {
      headers: {
        "Content-Type": "application/json",
        "Connection": "keep-alive",
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ processed: false, error: "server_error" }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
