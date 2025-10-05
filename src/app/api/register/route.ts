/* eslint-disable @typescript-eslint/no-explicit-any,no-console */
import { NextRequest, NextResponse } from 'next/server';

import { getConfig } from '@/lib/config';
import { db } from '@/lib/db';

export const runtime = 'nodejs';

/**
 * Public user registration endpoint
 * Guarded by:
 * - NEXT_PUBLIC_STORAGE_TYPE !== 'localstorage'
 * - NEXT_PUBLIC_ENABLE_REGISTER === 'true'
 *
 * POST body: { username: string, password: string }
 */
export async function POST(request: NextRequest) {
  const storageType = process.env.NEXT_PUBLIC_STORAGE_TYPE || 'localstorage';

  // Registration only supported when using server-side storage
  if (storageType === 'localstorage') {
    return NextResponse.json(
      { error: '本地存储模式不支持注册' },
      { status: 400 }
    );
  }

  // Feature flag
  const enableRegister = process.env.NEXT_PUBLIC_ENABLE_REGISTER;
  if (enableRegister !== 'true') {
    return NextResponse.json({ error: '用户注册功能已关闭' }, { status: 403 });
  }

  try {
    const body = (await request.json()) as {
      username?: string;
      password?: string;
    };

    const username = (body.username || '').trim();
    const password = (body.password || '').trim();

    // Basic validation
    if (!username || !password) {
      return NextResponse.json(
        { error: '用户名和密码不能为空' },
        { status: 400 }
      );
    }

    // Disallow registering owner account name
    if (username === process.env.USERNAME) {
      return NextResponse.json(
        { error: '该用户名保留为站长，不能注册' },
        { status: 400 }
      );
    }

    // Check existing users
    const adminConfig = await getConfig();
    const existed = adminConfig.UserConfig.Users.find(
      (u) => u.username === username
    );
    if (existed) {
      return NextResponse.json({ error: '用户已存在' }, { status: 400 });
    }

    // Register in storage
    await db.registerUser(username, password);

    // Update config cache (role=user, not banned)
    adminConfig.UserConfig.Users.push({
      username,
      role: 'user',
      banned: false,
    } as any);

    await db.saveAdminConfig(adminConfig);

    return NextResponse.json(
      { ok: true },
      {
        headers: {
          'Cache-Control': 'no-store',
        },
      }
    );
  } catch (error) {
    console.error('注册接口异常:', error);
    return NextResponse.json(
      {
        error: '服务器错误',
        details: (error as Error).message,
      },
      { status: 500 }
    );
  }
}
