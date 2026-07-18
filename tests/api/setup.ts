import { mockIPC } from "@tauri-apps/api/mocks";
import { afterAll, afterEach, beforeAll, expect, vi } from "vitest";
import { db } from "$lib/db";
import { STREAM } from "$lib/utils/faker";

export const LOCAL_TEST_PUBLIC_KEY =
  "34dae7402bdf9049e96e1a02bbae97baa714c498324538f81c7b4ba0a94bf4d7";

export function setupTestIPC(publicKey = LOCAL_TEST_PUBLIC_KEY) {
  const processorErrors: unknown[][] = [];
  const consoleError = console.error.bind(console);
  const errorSpy = vi.spyOn(console, "error").mockImplementation((...args) => {
    if (
      typeof args[0] === "string" &&
      args[0].startsWith("failed processing application event:")
    ) {
      processorErrors.push(args);
      return;
    }

    consoleError(...args);
  });

  mockIPC((cmd) => {
    if (cmd === "public_key") {
      return publicKey;
    }
  });

  afterEach(() => {
    const unexpectedErrors = processorErrors.splice(0);
    expect(unexpectedErrors, "unexpected application processor errors").toEqual(
      [],
    );
  });

  afterAll(() => {
    errorSpy.mockRestore();
  });
}

export function setupSeedTestIPC() {
  setupTestIPC();

  beforeAll(async () => {
    await db.calendars.put({
      id: STREAM.id,
      ownerId: STREAM.owner,
      stream: STREAM,
      name: "Resolved test calendar",
      createdAt: BigInt(0),
      updatedAt: BigInt(0),
    });
  });
}
