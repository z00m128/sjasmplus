/*#############################################################################
# TCONVERT.H
#
# SCA Software International S.A.
# http://www.scasoftware.com
# scaadmin@scasoftware.com
#
# Copyright (c) 2000 SCA Software International S.A.
#
# Date: 01.05.2000
# Author: Zoran M.Todorovic
#
# This software is provided "AS IS", without a warranty of any kind.
# You are free to use/modify this code but leave this header intact.
#
#############################################################################*/

#ifndef __TCONVERT_H__
#define __TCONVERT_H__

#ifndef _INC_TCHAR
# include <tchar.h>
#endif
#ifndef _INC_CRTDBG
//# include <crtdbg.h>
#endif
#ifndef _WINDOWS_
# include <windows.h>
#endif

//=============================================================================
// class _tochar
// This class converts either WCHAR or CHAR string to a new CHAR string.
// Memory is allocated/deallocated using new/delete
//=============================================================================

class _tochar {
private:
  BOOL m_bAutoDelete;
  LPSTR m_szBuffer;

public:
  _tochar(LPCWSTR wszText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(wszText);
    int nLen = wcslen(wszText)+1;
    m_szBuffer = new CHAR [nLen];
    wcstombs(m_szBuffer, wszText, nLen);
  }
  _tochar(LPCSTR szText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(szText);
    int nLen = strlen(szText) + 1;
    m_szBuffer = new CHAR [nLen];
    strcpy(m_szBuffer, szText);
  }
  ~_tochar()
  {
    if (m_bAutoDelete) {
      _ASSERTE(m_szBuffer);
      delete [] m_szBuffer;
    }
  }
  operator LPSTR()
  {
    _ASSERTE(m_szBuffer);
    return (LPSTR)m_szBuffer;
  }
  operator LPCSTR()
  {
    _ASSERTE(m_szBuffer);
    return (LPCSTR)m_szBuffer;
  }
};

//=============================================================================
// class _towchar
// This class converts either WCHAR or CHAR string to a new WCHAR string.
// Memory is allocated/deallocated using new/delete
//=============================================================================

class _towchar {
private:
  BOOL m_bAutoDelete;
  LPWSTR m_wszBuffer;

public:
  _towchar(LPCWSTR wszText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(wszText);
    int nLen = wcslen(wszText)+1;
    m_wszBuffer = new WCHAR [nLen];
    wcscpy(m_wszBuffer, wszText);
  }
  _towchar(LPCSTR szText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(szText);
    int nLen = strlen(szText) + 1;
    m_wszBuffer = new WCHAR [nLen];
    mbstowcs(m_wszBuffer, szText, nLen);
  }
  ~_towchar()
  {
    if (m_bAutoDelete) {
      _ASSERTE(m_wszBuffer);
      delete [] m_wszBuffer;
    }
  }
  operator LPWSTR()
  {
    _ASSERTE(m_wszBuffer);
    return (LPWSTR)m_wszBuffer;
  }
  operator LPCWSTR()
  {
    _ASSERTE(m_wszBuffer);
    return (LPCWSTR)m_wszBuffer;
  }
};

//=============================================================================
// class _totchar
// This class converts a TCHAR string to a new TCHAR string.
// Memory is allocated/deallocated using new/delete
//=============================================================================

class _totchar {
private:
  BOOL m_bAutoDelete;
  LPTSTR m_tszBuffer;

public:
  _totchar(LPCSTR szText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(szText);
    int nLen = strlen(szText) + 1;
    m_tszBuffer = new _TCHAR [nLen];
    #if defined(UNICODE) || defined(_UNICODE)
    mbstowcs(m_tszBuffer, szText, nLen);
    #else
    strcpy(m_tszBuffer, szText);
    #endif
  }
  _totchar(LPCWSTR wszText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(wszText);
    int nLen = wcslen(wszText) + 1;
    m_tszBuffer = new _TCHAR [nLen];
    #if defined(UNICODE) || defined(_UNICODE)
    wcscpy(m_tszBuffer, wszText);
    #else
    wcstombs(m_tszBuffer, wszText, nLen);
    #endif
  }
  ~_totchar()
  {
    if (m_bAutoDelete) {
      _ASSERTE(m_tszBuffer);
      delete [] m_tszBuffer;
    }
  }
  operator LPTSTR()
  {
    _ASSERTE(m_tszBuffer);
    return (LPTSTR) m_tszBuffer;
  }
  operator LPCTSTR()
  {
    _ASSERTE(m_tszBuffer);
    return (LPCTSTR) m_tszBuffer;
  }
};

//=============================================================================
// class _cochar
// This class converts either WCHAR or CHAR string to a new CHAR string.
// Memory is allocated/deallocated using CoTaskMemAlloc/CoTaskMemFree.
//=============================================================================

class _cochar {
private:
  BOOL m_bAutoDelete;
  LPSTR m_szBuffer;

public:
  _cochar(LPCWSTR wszText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(wszText);
    int nLen = wcslen(wszText)+1;
    m_szBuffer = (LPSTR)::CoTaskMemAlloc(nLen * sizeof(CHAR));
    wcstombs(m_szBuffer, wszText, nLen);
  }
  _cochar(LPCSTR szText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(szText);
    int nLen = strlen(szText) + 1;
    m_szBuffer = (LPSTR)::CoTaskMemAlloc(nLen * sizeof(CHAR));
    strcpy(m_szBuffer, szText);
  }
  ~_cochar()
  {
    if (m_bAutoDelete)
      ::CoTaskMemFree(m_szBuffer);
  }
  operator LPSTR()
  {
    return (LPSTR)m_szBuffer;
  }
  operator LPCSTR()
  {
    return (LPCSTR)m_szBuffer;
  }
};

//=============================================================================
// class _towchar
// This class converts either WCHAR or CHAR string to a new WCHAR string.
// Memory is allocated/deallocated using CoTaskMemAlloc/CoTaskMemFree
//=============================================================================

class _cowchar {
private:
  BOOL m_bAutoDelete;
  LPWSTR m_wszBuffer;

public:
  _cowchar(LPCWSTR wszText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(wszText);
    int nLen = wcslen(wszText)+1;
    m_wszBuffer = (LPWSTR)::CoTaskMemAlloc(nLen * sizeof(WCHAR));
    wcscpy(m_wszBuffer, wszText);
  }
  _cowchar(LPCSTR szText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(szText);
    int nLen = strlen(szText) + 1;
    m_wszBuffer = (LPWSTR)::CoTaskMemAlloc(nLen * sizeof (WCHAR));
    mbstowcs(m_wszBuffer, szText, nLen);
  }
  ~_cowchar()
  {
    if (m_bAutoDelete)
      ::CoTaskMemFree(m_wszBuffer);
  }
  operator LPWSTR()
  {
    return (LPWSTR)m_wszBuffer;
  }
  operator LPCWSTR()
  {
    return (LPCWSTR)m_wszBuffer;
  }
};

//=============================================================================
// class _cotchar
// This class converts a TCHAR string to a new TCHAR string.
// Memory is allocated/deallocated using CoTaskMemAlloc/CoTaskMemFree
//=============================================================================

class _cotchar {
private:
  BOOL m_bAutoDelete;
  LPTSTR m_tszBuffer;

public:
  _cotchar(LPCSTR szText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(szText);
    int nLen = strlen(szText) + 1;
    m_tszBuffer = (LPTSTR)::CoTaskMemAlloc(nLen * sizeof(TCHAR));
    #if defined(UNICODE) || defined(_UNICODE)
    mbstowcs(m_tszBuffer, szText, nLen);
    #else
    strcpy(m_tszBuffer, szText);
    #endif
  }
  _cotchar(LPCWSTR wszText, BOOL bAutoDelete = TRUE)
  {
    m_bAutoDelete = bAutoDelete;
    _ASSERTE(wszText);
    int nLen = wcslen(wszText) + 1;
    m_tszBuffer = (LPTSTR)::CoTaskMemAlloc(nLen * sizeof(TCHAR));
    #if defined(UNICODE) || defined(_UNICODE)
    wcscpy(m_tszBuffer, wszText);
    #else
    wcstombs(m_tszBuffer, wszText, nLen);
    #endif
  }
  ~_cotchar()
  {
    if (m_bAutoDelete)
      ::CoTaskMemFree(m_tszBuffer);
  }
  operator LPTSTR()
  {
    return (LPTSTR) m_tszBuffer;
  }
  operator LPCTSTR()
  {
    return (LPCTSTR) m_tszBuffer;
  }
};

#endif

/*#############################################################################
# End of file
#############################################################################*/