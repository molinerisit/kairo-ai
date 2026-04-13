export type EventStatus = 'scheduled' | 'confirmed' | 'cancelled' | 'completed';

export interface CalendarEvent {
  id:           string;
  tenant_id:    string;
  title:        string;
  description:  string | null;
  starts_at:    string;
  ends_at:      string;
  status:       EventStatus;
  contact_data: Record<string, unknown>;
  metadata:     Record<string, unknown>;
  created_at:   string;
  updated_at:   string;
}
