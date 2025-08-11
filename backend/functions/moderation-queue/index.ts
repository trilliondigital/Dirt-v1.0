import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface QueueBody { page?: number; page_size?: number }

type ReportRecord = {
  id: string;
  postId: string;
  reason: string;
  createdAt: string;
  status: "pending" | "reviewed" | "actioned" | "dismissed";
  notes: string | null;
};

Deno.serve(async (req: Request) => {
  try {
    const body = (await req.json().catch(() => ({}))) as QueueBody;
    const page = Math.max(1, Number(body.page ?? 1));
    const pageSize = Math.min(50, Math.max(1, Number(body.page_size ?? 20)));

    // TODO: fetch from reports table with pagination & status filters
    const now = Date.now();
    const items: ReportRecord[] = Array.from({ length: pageSize }).map((_, i) => ({
      id: crypto.randomUUID(),
      postId: crypto.randomUUID(),
      reason: "red flag",
      createdAt: new Date(now - (i + (page - 1) * pageSize) * 60000).toISOString(),
      status: "pending",
      notes: null,
    }));

    return new Response(JSON.stringify(items), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
