import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

export const IceCreamCart = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    reagents = [],
    total_reagents,
    max_reagents,
    categories = [],
    inventory,
    flavors,
    cones,
  } = data;

  return (
    <Window
      width={700}
      height={600}>
      <Window.Content>

      </Window.Content>
    </Window>
  );
};
