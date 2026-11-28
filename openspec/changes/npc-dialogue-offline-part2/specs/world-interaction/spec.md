# Spec Delta

## MODIFIED Requirements

### Requirement: Interactable targets
Every NPC and every interactable object in the room SHALL have a unique id, a kind (`npc`
or `object`) and a display name. The prototype room SHALL contain the office NPCs (Linh,
Trang, Minh, and Hana) and the room objects (Document Shelf, PC Terminal, and Meeting Room
Screen).

#### Scenario: Prototype room content
- **WHEN** the office room is loaded
- **THEN** it contains NPCs "Linh" (kind `npc`, id `linh`), "Trang" (kind `npc`, id
  `trang`), "Minh" (kind `npc`, id `minh`), and "Hana" (kind `npc`, id `hana`), and
  objects "Document Shelf" (kind `object`, id `document_shelf`), "PC Terminal" (kind
  `object`, id `pc_terminal`), and "Meeting Room Screen" (kind `object`, id
  `meeting_screen`)

#### Scenario: Ids are unique
- **WHEN** the office room is loaded
- **THEN** no two targets share the same kind and id pair
