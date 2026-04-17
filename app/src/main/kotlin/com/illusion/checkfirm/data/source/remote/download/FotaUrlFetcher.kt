package com.illusion.checkfirm.data.source.remote.download

import com.fleeksoft.ksoup.Ksoup
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.android.Android
import io.ktor.client.request.get
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class FotaUrlFetcher {
    private val client = HttpClient(Android)

    suspend fun fetchDownloadUrl(model: String, csc: String, firmware: String, isTest: Boolean): String? = withContext(Dispatchers.IO) {
        try {
            val suffix = if (isTest) "version.test.xml" else "version.xml"
            val response = client.get("https://fota-cloud-dn.ospserver.net/firmware/$csc/$model/$suffix")
            if (response.status.value == 200) {
                val body = response.body<String>()
                val doc = Ksoup.parse(html = body)
                val baseUrl = doc.select("url").text()
                if (baseUrl.isNotBlank()) {
                    val fileName = firmware.replace("/", "_") + ".zip"
                    return@withContext if (baseUrl.endsWith("/")) baseUrl + fileName else "$baseUrl/$fileName"
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return@withContext null
    }
}
