export const APP_ROLES = ["owner", "admin", "reviewer", "uploader"] as const;

export type AppRole = (typeof APP_ROLES)[number];

export function isAdminRole(role: AppRole): boolean {
  return role === "owner" || role === "admin";
}

export function dashboardPath(role: AppRole): string {
  return isAdminRole(role) ? "/admin" : "/reviewer";
}

export function canAccessAdminSurface(role: AppRole): boolean {
  return isAdminRole(role);
}

export function canAccessReviewerSurface(role: AppRole): boolean {
  return role === "reviewer" || role === "uploader" || isAdminRole(role);
}
