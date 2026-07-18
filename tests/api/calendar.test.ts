// This is required to mock the indexedDB API and must be imported at the top of the module.
import "fake-indexeddb/auto";

import { processMessage } from "$lib/processor";
import { CALENDAR_ID } from "$lib/utils/faker";
import { calendar001End, calendar001Start, seedTestMessages } from "./data";
import { setupSeedTestIPC } from "./setup";
import { calendars } from "$lib/api";
import { beforeAll, expect, test } from "vitest";

setupSeedTestIPC();

beforeAll(async () => {
  for (const message of seedTestMessages()) {
    await processMessage(message);
  }
});

test("processes a calendar_created message", async () => {
  const calendar = await calendars.findById(CALENDAR_ID);
  expect(calendar).toBeTruthy();
  expect(calendar!.id).toBe(CALENDAR_ID);
  expect(calendar!.name).not.toBe("Resolved test calendar");
  expect(calendar!.startDate).toBe(calendar001Start);
  expect(calendar!.endDate).toBe(calendar001End);
});
