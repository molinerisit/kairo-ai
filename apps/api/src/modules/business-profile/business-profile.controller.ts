import type { Request, Response } from 'express';
import { getBusinessProfile, updateBusinessProfile } from './business-profile.service';
import { updateBusinessProfileSchema } from './business-profile.schema';

// GET /api/business-profile
export async function getProfileController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;

  try {
    const profile = await getBusinessProfile(tenantId);
    if (!profile) {
      res.status(404).json({ error: 'Perfil no encontrado' });
      return;
    }
    res.json(profile);
  } catch (err) {
    console.error('[BusinessProfile] GET error:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}

// PATCH /api/business-profile
export async function updateProfileController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;

  const parsed = updateBusinessProfileSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }

  try {
    const profile = await updateBusinessProfile(tenantId, parsed.data);
    res.json(profile);
  } catch (err) {
    console.error('[BusinessProfile] PATCH error:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}
