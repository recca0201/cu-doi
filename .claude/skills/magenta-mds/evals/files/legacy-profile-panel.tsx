import {
  Button,
  Dialog,
  DialogAction,
  DialogContent,
  DialogHeader,
  Indicator,
  Input,
  SearchInput,
  Tag,
  TagsInput,
} from '@ocean-network-express/magenta-react'

export function LegacyProfilePanel() {
  return (
    <Dialog open maxWidth="2xl">
      <DialogHeader title="Edit customer" />
      <DialogContent>
        <Input label="Customer name" size="xl" state="danger" helperText="Required" />
        <SearchInput label="Find teammate" variant="ghost" />
        <TagsInput label="Owners" labelAlignment="inline" />
        <Tag color="danger" variant="solid">High risk</Tag>
        <Indicator color="danger" variant="solid" size="xl">Pending</Indicator>
      </DialogContent>
      <DialogAction>
        <Button color="secondary" variant="solid">Cancel</Button>
        <Button color="danger" variant="fill">Delete</Button>
      </DialogAction>
    </Dialog>
  )
}