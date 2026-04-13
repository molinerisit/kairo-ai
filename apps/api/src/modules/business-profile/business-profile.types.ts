export interface ServiceItem {
  name:   string;
  price?: number;
}

export interface FaqItem {
  q: string;
  a: string;
}

export interface BusinessProfile {
  id:          string;
  tenant_id:   string;
  name:        string;        // de la tabla tenants
  tone:        string | null;
  description: string | null;
  address:     string | null;
  whatsapp:    string | null; // phone_number_id de WhatsApp Business
  hours:       Record<string, string>;
  services:    ServiceItem[];
  faqs:        FaqItem[];
  updated_at:  string;
}
