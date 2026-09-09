import Link from "next/link";

export default function NotFound() {
  return (
    <main className="auth-page">
      <section className="auth-card" style={{ textAlign: "center" }}>
        <div style={{
          fontSize: 72,
          lineHeight: 1,
          marginBottom: 8,
          letterSpacing: "-0.06em",
          fontWeight: 700,
          color: "var(--teal)",
          fontFamily: "Georgia, serif",
        }}>
          404
        </div>
        <p className="eyebrow" style={{ marginBottom: 4 }}>lost in the papers</p>
        <h1 style={{ fontSize: 28, marginBottom: 12 }}>
          This page doesn&apos;t exist.
        </h1>
        <p className="lede" style={{ margin: "0 auto 28px", textAlign: "center" }}>
          Maybe it was moved, maybe it never was. Either way, there&apos;s nothing here.
        </p>
        <div className="btn-stack" style={{ justifyContent: "center" }}>
          <Link className="button" href="/dashboard">
            Back to dashboard
          </Link>
          <Link className="button" href="/" style={{ background: "var(--muted)" }}>
            Go home
          </Link>
        </div>
      </section>
    </main>
  );
}
