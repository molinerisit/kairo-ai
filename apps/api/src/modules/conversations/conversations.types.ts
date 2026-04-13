export type ConversationStatus = 'open' | 'resolved' | 'archived';
export type MessageRole        = 'user' | 'assistant' | 'system';
export type Channel            = 'whatsapp' | 'web' | 'api';

export interface Conversation {
  id:              string;
  tenant_id:       string;
  channel:         Channel;
  contact_phone:   string | null;
  contact_name:    string | null;
  status:          ConversationStatus;
  assigned_to:     string | null;
  last_message_at: string | null;
  metadata:        Record<string, unknown>;
  created_at:      string;
  updated_at:      string;
}

export interface Message {
  id:              string;
  tenant_id:       string;
  conversation_id: string;
  role:            MessageRole;
  content:         string;
  agent_type:      string | null;
  external_id:     string | null;
  created_at:      string;
}
