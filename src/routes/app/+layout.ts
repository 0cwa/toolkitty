import type { LayoutLoad } from "./$types";
import { redirect } from "@sveltejs/kit";
import { access } from "$lib/api";

export const load: LayoutLoad = async ({ parent }) => {
  const parentData = await parent();
  const { publicKey, activeCalendarId } = parentData;

  if (!activeCalendarId) {
    redirect(307, "/");
  }

  const accessStatus = await access.checkStatus(publicKey, activeCalendarId);

  if (accessStatus == "pending") {
    // access status is pending, go to pending page
    redirect(307, "/request");
  }

  // TODO: handle rejected state. Where do we go?

  return {
    activeCalendarId,
  };
};
