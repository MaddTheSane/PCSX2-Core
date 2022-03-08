/*  PCSX2 - PS2 Emulator for PCs
 *  Copyright (C) 2002-2021  PCSX2 Dev Team
 *
 *  PCSX2 is free software: you can redistribute it and/or modify it under the terms
 *  of the GNU Lesser General Public License as published by the Free Software Found-
 *  ation, either version 3 of the License, or (at your option) any later version.
 *
 *  PCSX2 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 *  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 *  PURPOSE.  See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along with PCSX2.
 *  If not, see <http://www.gnu.org/licenses/>.
 */

#include "PCSX2GameCore.h"
#include "common/GL/ContextAGL.h"
#include "common/Assertions.h"
#include "common/Console.h"
#include "glad.h"
#include <dlfcn.h>

#if ! __has_feature(objc_arc)
#error "Compile this with -fobjc-arc"
#endif

namespace GL
{
	ContextAGL::ContextAGL(const WindowInfo& wi)
		: Context(wi)
	{
		m_opengl_module_handle = dlopen("/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL", RTLD_NOW);
		if (!m_opengl_module_handle)
			Console.Error("Could not open OpenGL.framework, function lookups will probably fail");
	}

	ContextAGL::~ContextAGL()
	{
	}

	std::unique_ptr<Context> ContextAGL::Create(const WindowInfo& wi, const Version* versions_to_try,
		size_t num_versions_to_try)
	{
		std::unique_ptr<ContextAGL> context = std::make_unique<ContextAGL>(wi);
		if (!context->Initialize(versions_to_try, num_versions_to_try))
			return nullptr;

		return context;
	}

	bool ContextAGL::Initialize(const Version* versions_to_try, size_t num_versions_to_try)
	{
		MakeCurrent();
		
		for (size_t i = 0; i < num_versions_to_try; i++)
		{
			const Version& cv = versions_to_try[i];
			if (cv.profile == Profile::NoProfile && CreateContext(nullptr, NSOpenGLProfileVersionLegacy, true))
			{
				// we already have the dummy context, so just use that
				m_version = cv;
				return true;
			}
			else if (cv.profile == Profile::Core)
			{
				if (cv.major_version > 4 || cv.minor_version > 1)
					continue;

				const NSOpenGLPixelFormatAttribute profile = (cv.major_version > 3 || cv.minor_version > 2) ? NSOpenGLProfileVersion4_1Core : NSOpenGLProfileVersion3_2Core;
				if (CreateContext(nullptr, static_cast<int>(profile), true))
				{
					m_version = cv;
					return true;
				}
			}
		}

		return false;
	}

	void* ContextAGL::GetProcAddress(const char* name)
	{
		void* addr = m_opengl_module_handle ? dlsym(m_opengl_module_handle, name) : nullptr;
		if (addr)
			return addr;

		return dlsym(RTLD_NEXT, name);
	}

	bool ContextAGL::ChangeSurface(const WindowInfo& new_wi)
	{
		m_wi.surface_width = new_wi.surface_width;
		m_wi.surface_height = new_wi.surface_height;
		return true;
	}

	void ContextAGL::ResizeSurface(u32 new_surface_width /*= 0*/, u32 new_surface_height /*= 0*/)
	{
		UpdateDimensions();
	}

	bool ContextAGL::UpdateDimensions()
	{
		return true;
	}

	bool ContextAGL::SwapBuffers()
	{
		[_current.renderDelegate didRenderFrameOnAlternateThread];

		return true;
	}

	bool ContextAGL::MakeCurrent()
	{
		[_current.renderDelegate willRenderFrameOnAlternateThread];

		return true;
	}

	bool ContextAGL::DoneCurrent()
	{
		return true;
	}

	bool ContextAGL::SetSwapInterval(s32 interval)
	{
		return true;
	}

	std::unique_ptr<Context> ContextAGL::CreateSharedContext(const WindowInfo& wi)
	{
		return nullptr;
	}

	bool ContextAGL::CreateContext(NSOpenGLContext* share_context, int profile, bool make_current)
	{
		return true;
	}

	void ContextAGL::BindContextToView()
	{

	}

	void ContextAGL::CleanupView()
	{
		m_view = nullptr;
	}
} // namespace GL
