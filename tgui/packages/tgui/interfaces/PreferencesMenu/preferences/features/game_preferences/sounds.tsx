import { CheckboxInput, FeatureNumeric, FeatureNumberInput, FeatureToggle } from "../base";

export const sound_tts: FeatureToggle = {
  name: 'Enable TTS',
  category: 'SOUND',
  description: `When enabled, be able to hear text-to-speech sounds in game.`,
  component: CheckboxInput,
};

export const sound_tts_volume: FeatureNumeric = {
  name: 'TTS Volume',
  category: 'SOUND',
  description: 'The volume that the text-to-speech sounds will play at.',
  component: FeatureNumberInput,
};
