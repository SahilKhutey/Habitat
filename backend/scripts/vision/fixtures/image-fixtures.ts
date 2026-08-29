// Image Fixtures Generator for Vision Inference Testing & Spikes
export interface RawImageFixture {
  id: string;
  name: string;
  width: number;
  height: number;
  data: Uint8Array;
  description: string;
}

export class ImageFixtures {
  /**
   * Generates a 192x192 RGB raw frame of a person standing upright
   */
  public static getPersonStanding(): RawImageFixture {
    const width = 192;
    const height = 192;
    const data = new Uint8Array(width * height * 3);

    for (let y = 0; y < height; y++) {
      const normY = y / height;
      for (let x = 0; x < width; x++) {
        const normX = x / width;
        const idx = (y * width + x) * 3;

        // Ambient background
        data[idx] = 45;
        data[idx + 1] = 48;
        data[idx + 2] = 52;

        // Head (circle at x=0.50, y=0.18)
        if (Math.hypot(normX - 0.50, normY - 0.18) < 0.08) {
          data[idx] = 220;
          data[idx + 1] = 190;
          data[idx + 2] = 160;
        }

        // Torso (vertical rectangle at x in [0.42, 0.58], y in [0.26, 0.55])
        if (normX >= 0.42 && normX <= 0.58 && normY >= 0.26 && normY <= 0.55) {
          data[idx] = 190;
          data[idx + 1] = 80;
          data[idx + 2] = 80;
        }

        // Arms (left & right vertical columns x in [0.32, 0.42] and [0.58, 0.68], y in [0.28, 0.58])
        if ((normX >= 0.32 && normX < 0.42 && normY >= 0.28 && normY <= 0.58) ||
            (normX > 0.58 && normX <= 0.68 && normY >= 0.28 && normY <= 0.58)) {
          data[idx] = 215;
          data[idx + 1] = 185;
          data[idx + 2] = 155;
        }

        // Legs (x in [0.40, 0.48] and [0.52, 0.60], y in [0.55, 0.90])
        if ((normX >= 0.40 && normX <= 0.48 && normY >= 0.55 && normY <= 0.90) ||
            (normX >= 0.52 && normX <= 0.60 && normY >= 0.55 && normY <= 0.90)) {
          data[idx] = 70;
          data[idx + 1] = 70;
          data[idx + 2] = 150;
        }
      }
    }

    return {
      id: 'person-standing',
      name: 'Person Standing Upright',
      width,
      height,
      data,
      description: 'Single human subject standing in frame with clear head, torso, arms, and legs.'
    };
  }

  /**
   * Generates a 192x192 RGB raw frame of an empty room (no person)
   */
  public static getEmptyRoom(): RawImageFixture {
    const width = 192;
    const height = 192;
    const data = new Uint8Array(width * height * 3);

    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const idx = (y * width + x) * 3;
        // Uniform wall/floor gradient with zero human features
        data[idx] = 50 + (y % 4);
        data[idx + 1] = 52 + (x % 4);
        data[idx + 2] = 55;
      }
    }

    return {
      id: 'empty-room',
      name: 'Empty Room Background',
      width,
      height,
      data,
      description: 'Static indoor room without any human subjects or keypoint features.'
    };
  }
}
