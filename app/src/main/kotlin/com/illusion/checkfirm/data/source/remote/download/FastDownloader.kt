package com.illusion.checkfirm.data.source.remote.download

import io.ktor.client.HttpClient
import io.ktor.client.engine.android.Android
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.request
import io.ktor.client.statement.bodyAsChannel
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.utils.io.readAvailable
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.io.File
import java.io.RandomAccessFile

class FastDownloader(private val client: HttpClient = HttpClient(Android)) {

    suspend fun downloadFile(url: String, destination: File, numThreads: Int = 4, onProgress: (Long, Long) -> Unit) = coroutineScope {
        val headResponse = client.request(url) {
            method = HttpMethod.Get
            header(HttpHeaders.Range, "bytes=0-0")
        }

        val contentRange = headResponse.headers[HttpHeaders.ContentRange]
        val contentLength = if (contentRange != null && contentRange.contains("/")) {
            contentRange.substringAfterLast("/").toLong()
        } else {
            headResponse.headers[HttpHeaders.ContentLength]?.toLong() ?: return@coroutineScope
        }

        val chunkSize = contentLength / numThreads
        val deferreds = (0 until numThreads).map { i ->
            async(Dispatchers.IO) {
                val start = i * chunkSize
                val end = if (i == numThreads - 1) contentLength - 1 else (i + 1) * chunkSize - 1
                downloadChunk(url, destination, start, end)
            }
        }

        onProgress(0, contentLength)
        deferreds.awaitAll()
        onProgress(contentLength, contentLength)
    }

    private suspend fun downloadChunk(url: String, destination: File, start: Long, end: Long) = withContext(Dispatchers.IO) {
        val response = client.get(url) {
            header(HttpHeaders.Range, "bytes=$start-$end")
        }

        val channel = response.bodyAsChannel()
        val raf = RandomAccessFile(destination, "rw")
        raf.seek(start)

        try {
            val buffer = ByteArray(8192)
            while (!channel.isClosedForRead) {
                val read = channel.readAvailable(buffer)
                if (read <= 0) break
                raf.write(buffer, 0, read)
            }
        } finally {
            raf.close()
        }
    }
}
