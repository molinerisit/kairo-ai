import { z } from 'zod';

const serviceItemSchema = z.object({
  name:  z.string().min(1),
  price: z.number().positive().optional(),
});

const faqItemSchema = z.object({
  q: z.string().min(1),
  a: z.string().min(1),
});

export const updateBusinessProfileSchema = z.object({
  name:        z.string().min(1).max(120).optional(),
  tone:        z.string().max(120).optional(),
  description: z.string().max(1000).optional(),
  address:     z.string().max(300).optional(),
  whatsapp:    z.string().max(50).optional(),
  hours:       z.record(z.string(), z.string()).optional(),
  services:    z.array(serviceItemSchema).optional(),
  faqs:        z.array(faqItemSchema).optional(),
});

export type UpdateBusinessProfileInput = z.infer<typeof updateBusinessProfileSchema>;
